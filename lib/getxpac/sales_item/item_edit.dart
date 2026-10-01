import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:own/getxpac/sales_item/item_controller.dart';
import 'package:own/utils/image_picker.dart';

class StockEditPage extends StatefulWidget {
  final Map<String, dynamic> product; // Edit කරන්න ඕනෙ කරන item එකේ data ටික

  const StockEditPage({super.key, required this.product});

  @override
  State<StockEditPage> createState() => _StockEditPageState();
}

class _StockEditPageState extends State<StockEditPage> {
  final StockListController controller = Get.find<StockListController>();

  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController balanceController;
  late TextEditingController descriptionController;

  // 🌟 Dropdown එකට අදාළ Variable එක
  String? selectedCategory;

  // 🌟 Available Categories List එක
  final List<String> categories = ["Smart Things", "Accessories"];

  // 🌟 Image Handle කරන්න variables දෙකක් ගන්නවා
  String? _mainImageUrl;
  List<String> _galleryImageUrls = [];
  bool isActive = true;

  @override
  void initState() {
    super.initState();
    // දැනට තියෙන දත්ත ටික පටන් ගද්දිම TextFields වලට දානවා
    nameController = TextEditingController(text: widget.product['item_name']);
    priceController = TextEditingController(
      text: widget.product['price'].toString(),
    );
    balanceController = TextEditingController(
      text: widget.product['balance'].toString(),
    );
    descriptionController = TextEditingController(
      text: widget.product['description'] ?? '',
    );

    // 🌟 Firestore එකෙන් එන category එක අපේ list එකේ තියෙනවද බලලා set කරගන්නවා
    String currentCategory = widget.product['category'] ?? '';
    if (categories.contains(currentCategory)) {
      selectedCategory = currentCategory;
    } else {
      selectedCategory = categories.first; // Default එකක් විදිහට පළමු එක දෙනවා
    }

    // 🌟 Firestore එකෙන් දැනට තියෙන Main Image එක සහ Gallery Images ටික Load කරගැනීම
    _mainImageUrl = widget.product['main_image'];

    if (widget.product['images'] != null) {
      _galleryImageUrls = List<String>.from(widget.product['images']);
    }

    isActive = widget.product['isActive'] ?? true;
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    balanceController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  // 📸 Main Image එක Upload කරන්න BottomSheet එක open කරන Function එක
  void _openMainImageUploader() {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.6,
        color: Colors.white,
        child: ImageUploadWidget(
          storagePath: 'products/main/',
          onUploaded: (url) {
            setState(() {
              _mainImageUrl = url;
            });
            Get.back(); // Upload වුණාම BottomSheet එක Close කරන්න
          },
        ),
      ),
      isScrollControlled: true,
    );
  }

  // 📸 Gallery එකට අලුත් Image එකක් එකතු කරන්න Open කරන Function එක
  void _openGalleryImageUploader() {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.6,
        color: Colors.white,
        child: ImageUploadWidget(
          storagePath: 'products/gallery/',
          onUploaded: (url) {
            setState(() {
              _galleryImageUrls.add(url); // ලිස්ට් එකට එකතු කරනවා
            });
            Get.back();
          },
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Stock Item"),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 10),

              // ==========================================
              // 🖼️ SECTION 1: MAIN IMAGE (COVER IMAGE)
              // ==========================================
              const Text(
                "Main Product Image (Thumbnail)",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: GestureDetector(
                  onTap: _openMainImageUploader,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.blueGrey.shade400,
                            width: 2,
                          ),
                          image:
                              _mainImageUrl != null && _mainImageUrl!.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(_mainImageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _mainImageUrl == null || _mainImageUrl!.isEmpty
                            ? const Icon(
                                Icons.add_a_photo,
                                size: 40,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.blueGrey,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ==========================================
              // 🖼️ SECTION 2: GALLERY IMAGES (MORE IMAGES)
              // ==========================================
              const Text(
                "Product Gallery (Additional Images)",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount:
                      _galleryImageUrls.length + 1, // +1 දැම්මේ Add Button එකට
                  itemBuilder: (context, index) {
                    if (index == _galleryImageUrls.length) {
                      // ➕ අලුත් Image එකක් Add කරන Button එක
                      return GestureDetector(
                        onTap: _openGalleryImageUploader,
                        child: Container(
                          width: 90,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade400,
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.grey,
                            size: 30,
                          ),
                        ),
                      );
                    }

                    // 🖼️ Gallery එකේ තියෙන පින්තූර පෙන්වීම
                    return Stack(
                      children: [
                        Container(
                          width: 90,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: NetworkImage(_galleryImageUrls[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        // ❌ Image එක අයින් කරන්න පුළුවන් Delete Button එකක්
                        Positioned(
                          top: 4,
                          right: 12,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _galleryImageUrls.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // 1. Item Name Field
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Item Name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_bag_rounded),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Please enter item name" : null,
              ),
              const SizedBox(height: 16),

              // 2. Price Field
              TextFormField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: "Price (LKR)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money_rounded),
                ),
                validator: (value) {
                  if (value!.isEmpty) return "Please enter price";
                  if (double.tryParse(value) == null) {
                    return "Enter a valid price";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 3. Balance / Stock Field
              TextFormField(
                controller: balanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Current Stock Balance",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory_2_rounded),
                ),
                validator: (value) {
                  if (value!.isEmpty) return "Please enter stock balance";
                  if (int.tryParse(value) == null) {
                    return "Enter a valid integer";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 4. Description Field
              TextFormField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 🌟 5. Dynamic Category Dropdown Field (Updated)
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: const InputDecoration(
                  labelText: "Category",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                items: categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedCategory = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? "Please select a category" : null,
              ),
              const SizedBox(height: 16),

              // 6. Active Switch
              SwitchListTile(
                title: const Text('Is Item Active'),
                value: isActive,
                activeThumbColor: Colors.green,
                onChanged: (val) {
                  setState(() {
                    isActive = val;
                  });
                },
              ),
              const SizedBox(height: 24),

              // ==========================================
              // 💾 UPDATE BUTTON
              // ==========================================
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: controller.isLoading.value
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              // 🌟 Controller එකට `selectedCategory` එක කෙලින්ම pass කරනවා
                              await controller.editStockItem(
                                productId: widget.product['id'],
                                name: nameController.text.trim(),
                                description: descriptionController.text.trim(),
                                category: selectedCategory ?? '', // 🔥 Updated
                                price: double.parse(priceController.text),
                                balance: int.parse(balanceController.text),
                                isActive: isActive,
                                mainImage: _mainImageUrl ?? '',
                                images: _galleryImageUrls,
                              );

                              Navigator.of(context).pop();
                            }
                          },
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "UPDATE STOCK ITEM",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
