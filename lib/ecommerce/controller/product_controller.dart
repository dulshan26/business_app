import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/snackbar/snackbar.dart';
import 'package:get/state_manager.dart';
import 'package:own/ecommerce/models/product_model.dart';

class ProductController extends GetxController {
  final FirebaseFirestore _firebase = FirebaseFirestore.instance;

  var isLoading = false.obs;

  Future<void> addProduct(ProductModel product) async {
    isLoading.value = true;
    try {
      await _firebase
          .collection('products')
          .doc(product.id)
          .set(product.toMap());

      Get.snackbar(
        'Success',
        'Product added successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add product: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Stream<QuerySnapshot> getProducts() {
    return _firebase.collection('products').snapshots();
  }

  Future<void> deleteProduct(String productId) async {
    isLoading.value = true;
    try {
      await _firebase.collection('products').doc(productId).delete();

      Get.snackbar(
        'Success',
        'Product deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete product: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
