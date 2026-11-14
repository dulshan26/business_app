import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:own/getxpac/sales_item/item_controller.dart';
import 'package:own/getxpac/sales_item/item_model.dart';

class StockActionDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  final String type;

  const StockActionDialog({
    super.key,
    required this.product,
    required this.type,
  });

  @override
  State<StockActionDialog> createState() => _StockActionDialogState();
}

class _StockActionDialogState extends State<StockActionDialog> {
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _selectedOptionName;
  String? _selectedVariantName;
  bool _isSaving = false;

  ItemModel get _item => ItemModel.fromMap(widget.product);
  bool get _isIn => widget.type == 'in';
  bool get _hasVariants => _item.options.any((option) => option.variants.isNotEmpty);

  int? get _selectedVariantStock {
    if (_selectedOptionName == null || _selectedVariantName == null) {
      return null;
    }
    for (final option in _item.options) {
      if (option.name != _selectedOptionName) continue;
      for (final variant in option.variants) {
        if (variant.name == _selectedVariantName) return variant.stock;
      }
    }
    return null;
  }

  int get _currentBalance =>
      _hasVariants ? (_selectedVariantStock ?? 0) : _item.stock;

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });
    final success = await Get.find<StockListController>().updateStock(
      productId: widget.product['id'].toString(),
      itemName: widget.product['item_name']?.toString() ?? _item.name,
      quantity: int.parse(_quantityController.text.trim()),
      type: widget.type,
      note: _noteController.text.trim(),
      optionName: _selectedOptionName,
      variantName: _selectedVariantName,
    );
    if (!mounted) return;
    if (success) Get.back();
    setState(() {
      _isSaving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _isIn ? Colors.green.shade700 : Colors.red.shade700;
    final selectedOption = _item.options
        .where((option) => option.name == _selectedOptionName)
        .firstOrNull;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            _isIn ? Icons.add_circle_outline : Icons.remove_circle_outline,
            color: themeColor,
          ),
          const SizedBox(width: 10),
          Text(
            _isIn ? 'Stock In (Restock)' : 'Stock Out (Sale)',
            style: TextStyle(color: themeColor, fontSize: 18),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Item: ${widget.product['item_name'] ?? _item.name}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (_hasVariants) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedOptionName,
                  decoration: const InputDecoration(
                    labelText: 'Option',
                    border: OutlineInputBorder(),
                  ),
                  items: _item.options
                      .where((option) => option.variants.isNotEmpty)
                      .map(
                        (option) => DropdownMenuItem(
                          value: option.name,
                          child: Text(option.name),
                        ),
                      )
                      .toList(),
                  validator: (value) =>
                      value == null ? 'Select an option' : null,
                  onChanged: (value) {
                    setState(() {
                      _selectedOptionName = value;
                      _selectedVariantName = null;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(_selectedOptionName),
                  initialValue: _selectedVariantName,
                  decoration: const InputDecoration(
                    labelText: 'Variant',
                    border: OutlineInputBorder(),
                  ),
                  items: selectedOption?.variants
                      .map(
                        (variant) => DropdownMenuItem(
                          value: variant.name,
                          child: Text(
                            '${variant.name} (Stock: ${variant.stock})',
                          ),
                        ),
                      )
                      .toList(),
                  validator: (value) =>
                      value == null ? 'Select a variant' : null,
                  onChanged: selectedOption == null
                      ? null
                      : (value) {
                          setState(() {
                            _selectedVariantName = value;
                          });
                        },
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Current stock: ${_hasVariants && _selectedVariantStock == null ? 'Select a variant' : _currentBalance}',
                style: const TextStyle(color: Colors.grey),
              ),
              const Divider(height: 24),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pin),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter quantity';
                  final quantity = int.tryParse(value);
                  if (quantity == null || quantity <= 0) {
                    return 'Enter a valid number';
                  }
                  if (_hasVariants && _selectedVariantStock == null) {
                    return 'Select an option variant';
                  }
                  if (!_isIn && quantity > _currentBalance) {
                    return 'Not enough stock available';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note / Description (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Get.back(),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: themeColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}
