import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:own/utils/image_picker.dart'; // ඔයාගේ ImageUploadWidget එක තියෙන path එක

class AdminBannerManager extends StatefulWidget {
  const AdminBannerManager({super.key});

  @override
  State<AdminBannerManager> createState() => _AdminBannerManagerState();
}

class _AdminBannerManagerState extends State<AdminBannerManager> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _bannerTitleController = TextEditingController();
  final TextEditingController _bannerSubtitleController =
      TextEditingController();
  final TextEditingController _p1IdController = TextEditingController();
  final TextEditingController _p2IdController = TextEditingController();

  // Image URL States
  String? _bannerImageUrl;
  String? _p1ImageUrl;
  String? _p2ImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingBannerData();
  }

  // Firestore එකෙන් තියෙන data ටික form එකට load කර ගැනීම
  Future<void> _loadExistingBannerData() async {
    var doc = await FirebaseFirestore.instance
        .collection('banners')
        .doc('hero_banner')
        .get();
    if (doc.exists) {
      var data = doc.data() as Map<String, dynamic>;
      setState(() {
        _bannerTitleController.text = data['banner_title'] ?? '';
        _bannerSubtitleController.text = data['banner_subtitle'] ?? '';
        _p1IdController.text = data['product1_id'] ?? '';
        _p2IdController.text = data['product2_id'] ?? '';
        _bannerImageUrl = data['banner_image'];
        _p1ImageUrl = data['product1_image'];
        _p2ImageUrl = data['product2_image'];
      });
    }
  }

  // BottomSheet Uploader එක open කිරීම (Slot එක අනුව state එක update වෙනවා)
  void _openUploader(String slot) {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.6,
        color: Colors.white,
        child: ImageUploadWidget(
          storagePath: 'banners/',
          onUploaded: (url) {
            setState(() {
              if (slot == 'main') {
                _bannerImageUrl = url;
              } else if (slot == 'p1')
                // ignore: curly_braces_in_flow_control_structures
                _p1ImageUrl = url;
              else if (slot == 'p2')
                // ignore: curly_braces_in_flow_control_structures
                _p2ImageUrl = url;
            });
            Get.back();
          },
        ),
      ),
      isScrollControlled: true,
    );
  }

  // ඔක්කොම Data ටික එක පාර Firestore එකට Save කිරීම
  Future<void> _saveAllBannerData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('banners')
          .doc('hero_banner')
          .set({
            'banner_title': _bannerTitleController.text.trim(),
            'banner_subtitle': _bannerSubtitleController.text.trim(),
            'banner_image': _bannerImageUrl ?? '',
            'product1_id': _p1IdController.text.trim(),
            'product2_id': _p2IdController.text.trim(),
            'product1_image': _p1ImageUrl ?? '',
            'product2_image': _p2ImageUrl ?? '',
          }, SetOptions(merge: true));

      Get.snackbar(
        "Success",
        "Hero Section Saved Successfully!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Hero Section"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================
              // 🌅 1. MAIN HERO BANNER CHANGERS
              // ==========================================
              const Text(
                "1. Main Big Hero Banner Settings",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _bannerTitleController,
                        decoration: const InputDecoration(
                          labelText: "Banner Big Title",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _bannerSubtitleController,
                        decoration: const InputDecoration(
                          labelText: "Banner Subtitle",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Main Banner Background Image",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _openUploader('main'),
                        child: Container(
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade400),
                            image: _bannerImageUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(_bannerImageUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _bannerImageUrl == null
                              ? const Icon(
                                  Icons.add_a_photo,
                                  size: 36,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ==========================================
              // 🛍️ 2. TWO PRODUCT SLOTS CHANGERS
              // ==========================================
              const Text(
                "2. Bottom Products Cards Settings",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  // Slot 1
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            const Text(
                              "Product Slot 1",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _p1IdController,
                              decoration: const InputDecoration(
                                labelText: "Product ID",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () => _openUploader('p1'),
                              child: Container(
                                height: 100,
                                width: 100,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                  image: _p1ImageUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(_p1ImageUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: _p1ImageUrl == null
                                    ? const Icon(
                                        Icons.add_a_photo,
                                        color: Colors.grey,
                                      )
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Slot 2
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            const Text(
                              "Product Slot 2",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _p2IdController,
                              decoration: const InputDecoration(
                                labelText: "Product ID",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () => _openUploader('p2'),
                              child: Container(
                                height: 100,
                                width: 100,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                  image: _p2ImageUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(_p2ImageUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: _p2ImageUrl == null
                                    ? const Icon(
                                        Icons.add_a_photo,
                                        color: Colors.grey,
                                      )
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Save button
              Center(
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          minimumSize: const Size(250, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: const Text(
                          "SAVE WHOLE HERO SECTION",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: _saveAllBannerData,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
