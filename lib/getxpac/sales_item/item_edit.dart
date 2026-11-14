import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:own/getxpac/sales_item/item_controller.dart';
import 'package:own/getxpac/sales_item/item_model.dart';
import 'package:own/utils/image_picker.dart';

class StockEditPage extends StatefulWidget {
  final Map<String, dynamic>? product;

  const StockEditPage({super.key, this.product});

  @override
  State<StockEditPage> createState() => _StockEditPageState();
}

class _OptionEditor {
  final TextEditingController name;
  final List<_OptionVariantEditor> variants;

  _OptionEditor({String name = '', List<_OptionVariantEditor>? variants})
    : name = TextEditingController(text: name),
      variants = variants ?? [];

  factory _OptionEditor.fromModel(
    StockOptionModel model, {
    required String defaultPrice,
  }) {
    return _OptionEditor(
      name: model.name,
      variants: model.variants
          .map(
            (variant) => _OptionVariantEditor.fromModel(
              variant,
              defaultPrice: defaultPrice,
            ),
          )
          .toList(growable: true),
    );
  }

  void dispose() {
    name.dispose();
    for (final variant in variants) {
      variant.dispose();
    }
  }
}

class _OptionVariantEditor {
  final TextEditingController name;
  final TextEditingController price;
  final TextEditingController stock;

  _OptionVariantEditor({
    String name = '',
    String price = '0',
    String stock = '0',
  }) : name = TextEditingController(text: name),
       price = TextEditingController(text: price),
       stock = TextEditingController(text: stock);

  factory _OptionVariantEditor.fromModel(
    ProductOptionVariantModel model, {
    required String defaultPrice,
  }) {
    return _OptionVariantEditor(
      name: model.name,
      price: model.price?.toString() ?? defaultPrice,
      stock: model.stock.toString(),
    );
  }

  void dispose() {
    name.dispose();
    price.dispose();
    stock.dispose();
  }
}

class _StockEditPageState extends State<StockEditPage> {
  late final StockListController controller;

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
  List<String> _descriptionImageUrls = [];
  bool isActive = true;
  final List<_OptionEditor> _options = [];

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<StockListController>()
        ? Get.find<StockListController>()
        : Get.put(StockListController());

    final product = widget.product;
    nameController = TextEditingController(
      text: product?['item_name']?.toString() ?? '',
    );
    priceController = TextEditingController(
      text: product?['price']?.toString() ?? '0',
    );
    balanceController = TextEditingController(
      text: product?['balance']?.toString() ?? '0',
    );
    descriptionController = TextEditingController(
      text: product?['description']?.toString() ?? '',
    );

    final String currentCategory = product?['category']?.toString() ?? '';
    if (categories.contains(currentCategory)) {
      selectedCategory = currentCategory;
    } else {
      selectedCategory = categories.first;
    }

    _mainImageUrl = product?['main_image']?.toString();

    if (product?['images'] is List) {
      _galleryImageUrls = List<String>.from(product!['images']);
    }
    if (product?['description_images'] is List) {
      _descriptionImageUrls = List<String>.from(
        product!['description_images'],
      );
    }

    isActive = product?['isActive'] as bool? ?? true;

    if (product != null) {
      final item = ItemModel.fromMap(product);
      _options.addAll(
        item.options.map(
          (option) => _OptionEditor.fromModel(
            option,
            defaultPrice: priceController.text,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    balanceController.dispose();
    descriptionController.dispose();
    for (final option in _options) {
      option.dispose();
    }
    super.dispose();
  }

  List<StockOptionModel>? _readOptions() {
    final options = <StockOptionModel>[];
    final names = <String>{};

    for (final option in _options) {
      final name = option.name.text.trim();
      final variants = <ProductOptionVariantModel>[];
      final variantNames = <String>{};

      if (name.isEmpty || option.variants.isEmpty) {
        Get.snackbar(
          "Invalid option",
          "Enter an option name and add at least one variant.",
        );
        return null;
      }
      if (!names.add(name.toLowerCase())) {
        Get.snackbar("Invalid option", "Option names must be unique.");
        return null;
      }
      for (final variant in option.variants) {
        final variantName = variant.name.text.trim();
        final price = double.tryParse(variant.price.text.trim());
        final stock = int.tryParse(variant.stock.text.trim());
        if (variantName.isEmpty ||
            price == null ||
            price < 0 ||
            stock == null ||
            stock < 0) {
          Get.snackbar(
            "Invalid variant",
            "Enter a variant name, a valid non-negative price, and a valid non-negative stock count.",
          );
          return null;
        }
        if (!variantNames.add(variantName.toLowerCase())) {
          Get.snackbar(
            "Invalid variant",
            "Variant names must be unique within an option.",
          );
          return null;
        }
        variants.add(
          ProductOptionVariantModel(
            name: variantName,
            price: price,
            stock: stock,
          ),
        );
      }

      options.add(StockOptionModel(name: name, variants: variants));
    }

    return options;
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    final options = _readOptions();
    if (options == null) return;

    final baseStockText = balanceController.text.trim();
    final baseStock = int.tryParse(baseStockText);
    if (baseStock == null || baseStock < 0) {
      Get.snackbar(
        'Invalid stock',
        'Please enter a valid non-negative stock amount.',
      );
      return;
    }

    final stock = options.isEmpty
        ? baseStock
        : options
              .expand((option) => option.variants)
              .fold<int>(0, (total, variant) => total + variant.stock);

    final priceText = priceController.text.trim();
    final price = double.tryParse(priceText);
    if (price == null || price < 0) {
      Get.snackbar('Invalid price', 'Please enter a valid non-negative price.');
      return;
    }

    final bool saved;
    if (widget.product == null) {
      saved = await controller.addItem(
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
        category: selectedCategory ?? '',
        price: price,
        initialStock: stock,
        mainImage: _mainImageUrl ?? '',
        images: _galleryImageUrls,
        isActive: isActive,
        options: options,
        descriptionImages: _descriptionImageUrls,
      );
    } else {
      saved = await controller.editStockItem(
        productId: widget.product!['id'],
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
        category: selectedCategory ?? '',
        price: price,
        balance: stock,
        isActive: isActive,
        mainImage: _mainImageUrl ?? '',
        images: _galleryImageUrls,
        options: options,
        descriptionImages: _descriptionImageUrls,
      );
    }

    if (saved && mounted) {
      Navigator.of(context).pop();
    }
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

  void _openDescriptionImageUploader() {
    Get.bottomSheet(
      SizedBox(
        height: Get.height * 0.6,
        child: ImageUploadWidget(
          storagePath: 'products/description/',
          onUploaded: (url) {
            if (!mounted) return;
            setState(() {
              _descriptionImageUrls.add(url);
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
        title: Text(
          widget.product == null ? "Add Stock Item" : "Edit Stock Item",
        ),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                  final price = double.tryParse(value ?? '');
                  if (price == null) {
                    return "Enter a valid price";
                  }
                  if (price < 0) return "Price cannot be negative";
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 3. Balance / Stock Field
              TextFormField(
                controller: balanceController,
                enabled: _options.isEmpty,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Stock (used when there are no options)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory_2_rounded),
                ),
                validator: (value) {
                  final stock = int.tryParse(value ?? '');
                  if (stock == null) {
                    return "Enter a valid integer";
                  }
                  if (stock < 0) return "Stock cannot be negative";
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
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Description Images",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _openDescriptionImageUploader,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text("Add image"),
                  ),
                ],
              ),
              if (_descriptionImageUrls.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _descriptionImageUrls.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              _descriptionImageUrls[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    width: 100,
                                    height: 100,
                                    color: Colors.grey.shade200,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                    ),
                                  ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton(
                              onPressed: () {
                                setState(() {
                                  _descriptionImageUrls.removeAt(index);
                                });
                              },
                              constraints: const BoxConstraints.tightFor(
                                width: 28,
                                height: 28,
                              ),
                              padding: EdgeInsets.zero,
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black54,
                              ),
                              icon: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              "Options and Variants",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _options.add(_OptionEditor());
                              });
                            },
                            icon: const Icon(Icons.add),
                            label: const Text("Add option"),
                          ),
                        ],
                      ),
                      const Text(
                        "Add variants under each option and set each variant's stock.",
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      ..._options.asMap().entries.map((entry) {
                        final index = entry.key;
                        final option = entry.value;
                        return Card(
                          color: Colors.grey.shade50,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: option.name,
                                        decoration: const InputDecoration(
                                          labelText: "Option name",
                                          hintText: "Size",
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: "Remove option",
                                      onPressed: () {
                                        setState(() {
                                          _options.removeAt(index).dispose();
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...option.variants.asMap().entries.map((
                                  variantEntry,
                                ) {
                                  final variantIndex = variantEntry.key;
                                  final variant = variantEntry.value;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller: variant.name,
                                                decoration:
                                                    const InputDecoration(
                                                      labelText: "Variant",
                                                      hintText: "Small",
                                                      border:
                                                          OutlineInputBorder(),
                                                      isDense: true,
                                                    ),
                                              ),
                                            ),
                                            IconButton(
                                              tooltip: "Remove variant",
                                              onPressed: () {
                                                setState(() {
                                                  option.variants
                                                      .removeAt(variantIndex)
                                                      .dispose();
                                                });
                                              },
                                              icon: const Icon(
                                                Icons.remove_circle_outline,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller: variant.price,
                                                keyboardType:
                                                    const TextInputType.numberWithOptions(
                                                      decimal: true,
                                                    ),
                                                decoration:
                                                    const InputDecoration(
                                                      labelText: "Price",
                                                      border:
                                                          OutlineInputBorder(),
                                                      isDense: true,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: TextField(
                                                controller: variant.stock,
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration:
                                                    const InputDecoration(
                                                      labelText: "Stock",
                                                      border:
                                                          OutlineInputBorder(),
                                                      isDense: true,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        const Divider(height: 1),
                                      ],
                                    ),
                                  );
                                }),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      option.variants.add(
                                        _OptionVariantEditor(
                                          price: priceController.text,
                                        ),
                                      );
                                    });
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text("Add variant"),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
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
                    onPressed: controller.isLoading.value ? null : _saveItem,
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            widget.product == null
                                ? "SAVE ITEM"
                                : "UPDATE STOCK ITEM",
                            style: const TextStyle(
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
      ),
    );
  }
}
