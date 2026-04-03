import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

void showAddStockItemDialog(
  BuildContext parentContext, {
  int? nextItemId,
  DocumentSnapshot? docToEdit,
}) {
  showModalBottomSheet(
    context: parentContext,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 16.0,
        ),
        child: AddStockItemDialog(nextItemId: nextItemId, docToEdit: docToEdit),
      );
    },
  );
}

class AddStockItemDialog extends StatefulWidget {
  final int? nextItemId;
  final DocumentSnapshot? docToEdit;
  const AddStockItemDialog({super.key, this.nextItemId, this.docToEdit});

  @override
  State<AddStockItemDialog> createState() => _AddStockItemDialogState();
}

class _AddStockItemDialogState extends State<AddStockItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _itemIDController = TextEditingController();

  final CollectionReference stockCollection = FirebaseFirestore.instance
      .collection('stock');

  bool get isEditMode => widget.docToEdit != null;

  @override
  void initState() {
    super.initState();
    if (widget.docToEdit != null) {
      //edit mode - prefill field
      final data = widget.docToEdit!.data() as Map<String, dynamic>;
      _itemIDController.text = data['item_id'].toString();
      _itemNameController.text = data['item_name'] ?? '';
      _descriptionController.text = data['description'] ?? '';
    } else {
      //add mode - use next avaiable ID
      _itemIDController.text = (widget.nextItemId).toString();
    }
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _descriptionController.dispose();
    _itemIDController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isEditMode ? "Edit Stock Item" : "Add new Item",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextFormField(
              controller: _itemIDController,
              decoration: const InputDecoration(labelText: 'Item ID'),
            ),
            TextFormField(
              controller: _itemNameController,
              decoration: const InputDecoration(labelText: 'Item Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter item name';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final itemdata = {
                    'item_id': int.parse(_itemIDController.text),
                    'item_name': _itemNameController.text,
                    'description': _descriptionController.text,
                    'updated_at': FieldValue.serverTimestamp(),
                  };

                  try {
                    if (isEditMode) {
                      await stockCollection
                          .doc(widget.docToEdit!.id)
                          .update(itemdata);
                    } else {
                      itemdata['created_at'] = FieldValue.serverTimestamp();
                      itemdata['balance'] = 0;
                      await stockCollection.add(itemdata);

                      // ✅ check if still mounted before using context
                    }
                    if (!mounted) return;
                    Navigator.pop(context);

                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Item added successfully')),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding item: $e')),
                    );
                  }
                }
              },
              child: Text(isEditMode ? 'Update Item' : 'Add Item'),
            ),
          ],
        ),
      ),
    );
  }
}
