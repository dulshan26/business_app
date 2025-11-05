import 'package:flutter/material.dart';
import 'package:own/sales/order_model.dart';

class SalesItemEditor extends StatefulWidget {
  const SalesItemEditor({super.key});

  @override
  State<SalesItemEditor> createState() => _SalesItemEditorState();
}

class _SalesItemEditorState extends State<SalesItemEditor> {
  /// Adds a new item to the order with a default quantity of 1
  void addItem(ItemModel item) {
    setState(() {
      // Create a new instance with quantity 1
      selectedItems.add(ItemModel(id: item.id, name: item.name, quantity: 1));
    });
  }

  /// Increments the quantity of an item at a given index
  void _incrementQuantity(int index) {
    setState(() {
      selectedItems[index].quantity++;
    });
  }

  /// Decrements the quantity of an item, removing it if quantity becomes 0
  void _decrementQuantity(int index) {
    setState(() {
      if (selectedItems[index].quantity > 1) {
        selectedItems[index].quantity--;
      } else {
        // If quantity is 1, remove the item
        selectedItems.removeAt(index);
      }
    });
  }

  final List<ItemModel> selectedItems = [];
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: selectedItems.length,
        itemBuilder: (context, index) {
          final item = selectedItems[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(item.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red,
                    ),
                    onPressed: () => _decrementQuantity(index),
                  ),
                  Text(
                    item.quantity.toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.green,
                    ),
                    onPressed: () => _incrementQuantity(index),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
