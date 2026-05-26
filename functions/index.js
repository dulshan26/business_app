const { onDocumentUpdated, onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { setGlobalOptions } = require("firebase-functions/v2");
const functions = require('firebase-functions');
const admin = require("firebase-admin");
const axios = require("axios"); // SINGLE axios import

admin.initializeApp();
setGlobalOptions({ maxInstances: 10 });

/* -----------------------------------------------------
   1️⃣ CREATE COURIER ORDER WHEN COURIER SELECTED
----------------------------------------------------- */
exports.createCourierOrder = onDocumentUpdated(
  "sales/{saleId}",
  async (event) => {
    const newData = event.data.after.data();
    const oldData = event.data.before.data();

    // Only trigger when courier changes to Royal Courier AND no tracking number exists
    if (newData.curier === oldData.curier || 
        newData.curier !== "Royal Courier" || 
        newData.trackingNumber) {
      return null;
    }

    try {
      const response = await axios.post(
        "https://v1.api.curfox.com/api/public/merchant/order/single",
        {
          general_data: {
            merchant_business_id: "2",
            origin_city_name: "Aggona",
            origin_state_name: "Colombo Suburbs",
          },
          order_data: [{
            order_no: event.params.saleId,
            customer_name: newData.customerName,
            customer_address: newData.address,
            customer_phone: newData.phone,
            destination_city_name: "Colombo",
            destination_state_name: "Colombo",
            cod: newData.amount,
            weight: 1,
            description: "Online order",
          }],
        },
        {
          headers: {
            "Accept": "application/json",
            "Content-Type": "application/json",
            "Authorization": "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9...", // Replace with your token
            "X-tenant": "royalexpress",
          },
        }
      );

      const waybill = response.data.data[0].waybill_number;
      
      await event.data.after.ref.update({
        trackingNumber: waybill,
        courierPartner: "Royal Courier",
      });

      console.log("Courier order created:", waybill);
    } catch (error) {
      console.error("Courier API error:", error.response?.data || error.message);
    }
    return null;
  }
);

/* -----------------------------------------------------
   2️⃣a SMS ON ORDER CREATION
----------------------------------------------------- */
exports.sendSmsOnCreation = onDocumentCreated(
  "sales/{saleId}",
  async (event) => {
    const data = event.data.data();
    const ref = event.data.ref;

    let phone = data.phone || "";
    if (phone.startsWith("0")) {
      phone = "94" + phone.substring(1);
    } else if (phone.startsWith("+94")) {
      phone = phone.replace("+", "");
    }

    const items = data.items || [];
    const itemNames = items.map(i => `${i.name} (x${i.quantity})`).join(", ");

    const message =
`Hi ${data.customerName || "Customer"},

Your order has been placed!

Items: ${itemNames}
Amount: Rs.${data.amount || 0}
Status: Pending

- techtonic.lk`;

    try {
      await axios.post(
        "https://app.text.lk/api/v3/sms/send",
        {
          recipient: phone,
          sender_id: "Techtonic",
          message: message,
        },
        {
          headers: {
            "Authorization": "Bearer 3588|9uKNaobXPQaxNOq8lZglzpOug9ESWDx6HAL96lowbfcf50f6",
            "Content-Type": "application/json",
          },
        }
      );

      await ref.update({
        smsSent: "yes",
        smsSentAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log("Creation SMS sent for Sale ID:", event.params.saleId);

    } catch (error) {
      console.error("Creation SMS Error:", error.response?.data || error.message);
    }

    return null;
  }
);

/* -----------------------------------------------------
   2️⃣b SMS ON EVERY STATUS CHANGE
----------------------------------------------------- */
exports.sendSmsOnStatusChange = onDocumentUpdated(
  "sales/{saleId}",
  async (event) => {
    const newData = event.data.after.data();
    const oldData = event.data.before.data();

    // Only fire when courierStatus actually changes
    if (newData.courierStatus === oldData.courierStatus) {
      return null;
    }

    const db = admin.firestore();
    const ref = event.data.after.ref;

    // Atomic lock to prevent duplicate sends
    try {
      await db.runTransaction(async (t) => {
        const doc = await t.get(ref);
        if (doc.data().smsSent === "processing") {
          throw new Error("Already processing");
        }
        t.update(ref, { smsSent: "processing" });
      });
    } catch (e) {
      console.log("Lock failed:", e.message);
      return null;
    }

    let phone = newData.phone || "";
    if (phone.startsWith("0")) {
      phone = "94" + phone.substring(1);
    } else if (phone.startsWith("+94")) {
      phone = phone.replace("+", "");
    }

    const items = newData.items || [];
    const itemNames = items.map(i => `${i.name} (x${i.quantity})`).join(", ");

    const message =
`Hi ${newData.customerName || "Customer"},

Your order status has been updated!

Items: ${itemNames}
Amount: Rs.${newData.amount || 0}
Status: ${newData.courierStatus || "Pending"}
Tracking: ${newData.trackingNumber || "-"}

- techtonic.lk`;

    try {
      await axios.post(
        "https://app.text.lk/api/v3/sms/send",
        {
          recipient: phone,
          sender_id: "Techtonic",
          message: message,
        },
        {
          headers: {
            "Authorization": "Bearer 3588|9uKNaobXPQaxNOq8lZglzpOug9ESWDx6HAL96lowbfcf50f6",
            "Content-Type": "application/json",
          },
        }
      );

      await ref.update({
        smsSent: "yes",
        smsSentAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log("Status change SMS sent for Sale ID:", event.params.saleId);

    } catch (error) {
      await ref.update({ smsSent: "no" });
      console.error("Status SMS Error:", error.response?.data || error.message);
    }

    return null;
  }
);
/* -----------------------------------------------------
   3️⃣ DAILY COURIER STATUS SYNC (12 PM)
----------------------------------------------------- */
exports.dailyCourierSync = onSchedule(
  {
    schedule: "0 12 * * *",
    timeZone: "Asia/Colombo",
  },
  async () => {
    const db = admin.firestore();
    const snapshot = await db.collection("sales")
      .where("curier", "==", "Royal Courier")
      .where("trackingNumber", "!=", null)
      .get();

    for (const doc of snapshot.docs) {
      const data = doc.data();
      
      try {
        const response = await axios.post(
          "https://v1.api.curfox.com/api/public/order/tracking-info",
          { waybill_number: data.trackingNumber },
          {
            headers: {
              "Accept": "application/json",
              "Content-Type": "application/json",
              "X-tenant": "royalexpress",
              "Authorization": "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9...", // Replace with your token
            },
          }
        );

        const timeline = response.data.data.timeline;
        if (timeline && timeline.length > 0) {
          const latestStatus = timeline[0].status.name;
          
          await doc.ref.update({
            courierStatus: latestStatus,
            courierUpdated: admin.firestore.FieldValue.serverTimestamp(),
          });
          console.log(`Updated ${doc.id} → ${latestStatus}`);
        }
      } catch (error) {
        console.error(`Tracking failed for ${doc.id}:`, error.message);
      }
    }
    return null;


    
  }
);
/* -----------------------------------------------------
   2️⃣b SMS ON EVERY STATUS CHANGE (Updated for sales_new)
----------------------------------------------------- */
exports.sendSmsOnStatusChange = onDocumentUpdated(
  "sales_new/{saleId}", // මෙතැන පාර වෙනස් කළා
  async (event) => {
    const newData = event.data.after.data();
    const oldData = event.data.before.data();

    // 1. status එක හෝ courierStatus එක වෙනස් වෙලා නම් විතරක් වැඩේ කරන්න
    if (newData.courierStatus === oldData.courierStatus) {
      return null;
    }

    // 2. phone number එක format කරගන්න
    let phone = newData.customerPhone || "";
    if (phone.startsWith("0")) {
      phone = "94" + phone.substring(1);
    } else if (phone.startsWith("+94")) {
      phone = phone.replace("+", "");
    }

    const items = newData.items || [];
    const itemNames = items.map(i => `${i.name} (x${i.quantity})`).join(", ");

    const message =
`Hi ${newData.customerName || "Customer"},

Your order status has been updated to: ${newData.courierStatus || "Pending"}

Items: ${itemNames}
Tracking: ${newData.trackingNumber || "N/A"}

- techtonic.lk`;

    try {
      // 3. SMS API එකට request එක යවන්න
      await axios.post(
        "https://app.text.lk/api/v3/sms/send",
        {
          recipient: phone,
          sender_id: "Techtonic",
          message: message,
        },
        {
          headers: {
            "Authorization": "Bearer 3588|9uKNaobXPQaxNOq8lZglzpOug9ESWDx6HAL96lowbfcf50f6",
            "Content-Type": "application/json",
          },
        }
      );

      // 4. status එක update වෙච්ච වෙලාව record කරන්න
      await event.data.after.ref.update({
        courierUpdated: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log("Status change SMS sent for Sale ID (sales_new):", event.params.saleId);

    } catch (error) {
      console.error("Status SMS Error:", error.response?.data || error.message);
    }

    return null;
  }
);

