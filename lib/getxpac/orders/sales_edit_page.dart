import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:own/firebase/firestore.dart';
import 'package:own/getxpac/sales/sales_model.dart';

class SalesEditPage extends StatefulWidget {
  final SalesModel sales;
  const SalesEditPage({super.key, required this.sales});

  @override
  State<SalesEditPage> createState() => _SalesEditPageState();
}

class _SalesEditPageState extends State<SalesEditPage> {
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController phone2Controller;
  late TextEditingController addressController;
  late TextEditingController totalAmountController;
  late TextEditingController noteController;
  late TextEditingController courierStatusController;
  late TextEditingController trackingNumberController;
  late TextEditingController destinationCityController;

  // 🏢 Cities Dropdown එකට අදාළ Variables
  List<Map<String, dynamic>> curfoxCities = [];
  int? selectedCityId;
  String selectedCityName = "";
  String? selectedCityState = "";
  bool isLoadingCities = true;

  List<Map<String, dynamic>> editedItems = [];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.sales.customerName);
    phoneController = TextEditingController(text: widget.sales.customerPhone);
    phone2Controller = TextEditingController(text: widget.sales.custonerPhone2);
    addressController = TextEditingController(
      text: widget.sales.customerAddress,
    );
    totalAmountController = TextEditingController(
      text: widget.sales.totalAmount.toString(),
    );
    noteController = TextEditingController(text: widget.sales.note);
    courierStatusController = TextEditingController(
      text: widget.sales.courierStatus,
    );
    trackingNumberController = TextEditingController(
      text: widget.sales.trackingNumber,
    );

    editedItems = List<Map<String, dynamic>>.from(
      widget.sales.items.map((item) => Map<String, dynamic>.from(item)),
    );
    destinationCityController = TextEditingController(
      text: widget.sales.destinationCity,
    );

    selectedCityName =
        widget.sales.destinationCity ??
        ""; // ➕ (Assuming you have city ID stored in the sales model)
    selectedCityState = widget.sales.destinationState ?? "";

    // 🚀 පේජ් එක ඕපන් වෙද්දීම නගර ලැයිස්තුව ලෝඩ් කරනවා
    _loadCurfoxCities();
  }

  // 🌐 API එකෙන් නගර ලැයිස්තුව අරන් State එකට දාන ක්‍රියාවලිය
  Future<void> _loadCurfoxCities() async {
    try {
      // 💡 ඔයාගේ Token, Tenant විස්තර මෙතනට දාන්න මල්ලි
      String token =
          "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiIxIiwianRpIjoiYjFiNDk3OWM1YjEyNjEwNjUxMGFhZDMyMDQ0MzBiMWE0NWYyZTFiMzAzOTIzMTQ3ZjdjM2YyNWEzMGZkMDU0MzdhZWZjNmJiOTVkZWI2OTEiLCJpYXQiOjE3NzI3MzU4MzMuMjM2NDYzLCJuYmYiOjE3NzI3MzU4MzMuMjM2NDY1LCJleHAiOjQ5Mjg0MDk0MzMuMjIyMzE0LCJzdWIiOiI0Njc0Iiwic2NvcGVzIjpbXX0.jVbxQXE8AOGvYuWPQmDGA7VyYvPyw73AnyiCpGgdd0XD7GQCtMj5HLn0YNADASZwWOxRxK9J92OB0CW3KD_ZUtku7VYIbb8SYKOYDzBNrdt8EfiM7cKMf8vWaD22jnwi33_TEEdWzQxuI5HMqkq0AiKOm93lKgt94SGmeSl_xlWORKBENB4qvawCiQhRgluMnyxInC7mmbPGgHY1Mx_4IZ5nEXto3C6wrlLdfPJNTlWnJPALeHKiNPRLD6kHS0-Mo_wotlddLRuKSfj19kxkazfBm-cuH8cJj76pFCuVKbQCWzC-ok7gK2-ZwO3nvEq9VnEQrG62bxkgFe8orEZIfm3Saw99sbUr7EwoHOvMircz4FMHm-ls5c8VqUpy81xn8TyYeZ6mTyZk0oJ0mVso_JbN5wU6hmKmxX-amhA2UTQ1f20Ic61JVskkmZjkmDmdBQBU2yribDqzD06_SH3I7n8KueHYNXOElHo-D1Gp2wU05zTdROMurfegGzTvCeR8v6lAaDygLXyG2quK6RF0LN_kwXat6JqRCAuyedHfzts0TEe1Yps8LY1LfyW4PtcFaZcUoLPjQwsDcM6yE0237I1qDMNhobp_qB_3V1xkenN7sPkLn47iRodN7-PoFMzG3xzffZvm4tVJBRcKuvxgTSCDf2GkJZSbz20RRv7kDZo";
      String tenant = "royalexpress";

      List<Map<String, dynamic>> cities = await FirestoreService()
          .loadCurfoxCities(token: token, tenant: tenant);

      setState(() {
        curfoxCities = cities;
        isLoadingCities = false;
        if (selectedCityName.isNotEmpty) {
          final matchedCity = curfoxCities.firstWhere(
            (city) =>
                city['name'].toString().toLowerCase() ==
                selectedCityName.toLowerCase(),
            orElse: () => {},
          );
          if (matchedCity.isNotEmpty) {
            selectedCityId = matchedCity['id'];
            selectedCityState = matchedCity['state_name'] ?? "Colombo";
          }
        }
      });
    } catch (e) {
      setState(() {
        isLoadingCities = false;
      });
      Get.snackbar("Error", "Error loading cities into UI: $e");
    }
  }

  void _calculateTotal() {
    double total = 0.0;
    for (var item in editedItems) {
      double price = double.tryParse(item['price'].toString()) ?? 0.0;
      int qty = int.tryParse(item['quantity'].toString()) ?? 1;
      total += (price * qty);
    }
    setState(() {
      totalAmountController.text = total.toStringAsFixed(2);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Edit Order Details",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Customer Information"),
            const SizedBox(height: 10),
            _buildTextField(nameController, "Customer Name", Icons.person),
            _buildTextField(
              phoneController,
              "Phone 1",
              Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            _buildTextField(
              phone2Controller,
              "Phone 2",
              Icons.phone_android,
              keyboardType: TextInputType.phone,
            ),
            _buildTextField(
              addressController,
              "Address",
              Icons.home,
              maxLines: 2,
            ),
            _buildTextField(noteController, "Order Note/Comment", Icons.note),

            const Divider(height: 30),
            _buildSectionTitle("Courier & Shipping"),
            const SizedBox(height: 10),

            // 📍 DESTINATION CITY SEARCHABLE DROPDOWN
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: isLoadingCities
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text(
                              "Loading Sri Lankan Cities...",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Autocomplete<Map<String, dynamic>>(
                      initialValue: TextEditingValue(text: selectedCityName),
                      displayStringForOption: (Map<String, dynamic> option) =>
                          option['name'],
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<Map<String, dynamic>>.empty();
                        }
                        // 🔍 User ටයිප් කරන අකුරු අනුව Cities ලිස්ට් එක Filter කරනවා (Case Insensitive)
                        return curfoxCities.where((
                          Map<String, dynamic> option,
                        ) {
                          return option['name']
                              .toString()
                              .toLowerCase()
                              .contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      onSelected: (Map<String, dynamic> selection) {
                        setState(() {
                          selectedCityId = selection['id'];
                          selectedCityName = selection['name'];
                        });
                        Get.snackbar(
                          "City Selected",
                          "Selected City: $selectedCityName (ID: $selectedCityId)",
                        );
                      },
                      fieldViewBuilder:
                          (
                            context,
                            textController,
                            focusNode,
                            onFieldSubmitted,
                          ) {
                            return TextField(
                              controller: textController,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                labelText: "Destination City",
                                prefixIcon: Icon(
                                  Icons.location_city,
                                  color: Colors.blue.shade800,
                                  size: 20,
                                ),
                                suffixIcon: const Icon(Icons.arrow_drop_down),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                            );
                          },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: MediaQuery.of(context).size.width - 32,
                              height: 250, // Popup වෙන ලිස්ට් එකේ උපරිම උස
                              color: Colors.white,
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final Map<String, dynamic> option = options
                                      .elementAt(index);
                                  return ListTile(
                                    title: Text(
                                      option['name'],
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            _buildTextField(
              courierStatusController,
              "Courier Status",
              Icons.local_shipping,
            ),
            _buildTextField(
              trackingNumberController,
              "Tracking Number",
              Icons.qr_code,
            ),

            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle("Order Items"),
                IconButton(
                  onPressed: _addNewItem,
                  icon: const Icon(
                    Icons.add_circle,
                    color: Colors.green,
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 🛒 Items List Display
            editedItems.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        "No items added to this order.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: editedItems.length,
                    itemBuilder: (context, index) {
                      final item = editedItems[index];
                      double itemPrice =
                          double.tryParse(item['price'].toString()) ?? 0.0;
                      int itemQty =
                          int.tryParse(item['quantity'].toString()) ?? 1;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'] ?? "Unknown Item",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Rs. ${itemPrice.toStringAsFixed(2)} x $itemQty = Rs. ${(itemPrice * itemQty).toStringAsFixed(2)}",
                                      style: TextStyle(
                                        color: Colors.blue.shade900,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.orange,
                                    ),
                                    onPressed: () {
                                      if (itemQty > 1) {
                                        setState(() {
                                          editedItems[index]['quantity'] =
                                              itemQty - 1;
                                        });
                                        _calculateTotal();
                                      }
                                    },
                                  ),
                                  Text(
                                    "$itemQty",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        editedItems[index]['quantity'] =
                                            itemQty + 1;
                                      });
                                      _calculateTotal();
                                    },
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() {
                                    editedItems.removeAt(index);
                                  });
                                  _calculateTotal();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

            const Divider(height: 40),
            _buildTextField(
              totalAmountController,
              "Total Amount (Rs.)",
              Icons.attach_money,
              keyboardType: TextInputType.number,
              readOnly: true,
            ),
            const SizedBox(height: 24),

            // 💾 Save Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _saveOrderChanges,
                child: const Text(
                  "Save Changes",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 💾 Firebase Save
  Future<void> _saveOrderChanges() async {
    Map<String, dynamic> updatedData = {
      'customerName': nameController.text,
      'customerPhone': phoneController.text,
      'custonerPhone2': phone2Controller.text,
      'customerAddress': addressController.text,
      'totalAmount': double.tryParse(totalAmountController.text) ?? 0.0,
      'note': noteController.text,
      'courierStatus': courierStatusController.text,
      'items': editedItems,
      'trackingNumber': trackingNumberController.text,

      // 🌟 NEW: තෝරාගත් නගරයේ නම සහ ID එක Firestore එකට යවනවා
      'destinationCity': selectedCityName,
      'destinationCityId': selectedCityId,
      'destinationState': selectedCityState,

      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await FirestoreService().updateSalesOrder(widget.sales.id!, updatedData);
      if (mounted) {
        Get.back();
        Get.snackbar(
          "Success",
          "Order updated successfully!",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
      Get.back(); // Save කරලා පසුපසට යන්න
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to update: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _addNewItem() {
    // 💡 (මීට කලින් පියවරේ ලියපු _addNewItem විජට් එක එලෙසම පවතී)
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: Colors.blue.shade800),
          filled: readOnly,
          fillColor: readOnly ? Colors.grey.shade100 : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Colors.blue.shade900,
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    phone2Controller.dispose();
    addressController.dispose();
    totalAmountController.dispose();
    noteController.dispose();
    courierStatusController.dispose();
    trackingNumberController.dispose();

    super.dispose();
  }
}
