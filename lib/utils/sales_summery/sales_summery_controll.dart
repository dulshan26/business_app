import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/route_manager.dart';
import 'package:get/state_manager.dart';
import 'package:own/utils/sales_summery/sales_summery.dart';

class SalesSummeryControll extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  var summery = SalesSummery(totalOrders: 0, totalRevenew: 0.0).obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    bindSummeryStream();
  }

  void bindSummeryStream() {
    _db
        .collection('sales_summary')
        .doc('overall')
        .snapshots()
        .listen(
          (doc) {
            if (doc.exists) {
              summery.value = SalesSummery.fromSnapshot(doc);
            }
            isLoading.value = false;
          },
          onError: (error) {
            isLoading.value = false;
            Get.snackbar("Error", "Error is = $error");
          },
        );
  }
}
