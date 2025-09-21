import 'package:flutter/material.dart';
import 'package:own/models/order_model.dart';

class OrderItemsPage extends StatefulWidget {
  const OrderItemsPage({super.key});

  @override
  State<OrderItemsPage> createState() => _OrderItemsPageState();
}

class _OrderItemsPageState extends State<OrderItemsPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sales Order Items")),
      body: Column(
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(labelText: "Enter item name"),
          ),
          ElevatedButton(onPressed: () {}, child: const Text("Add Item")),
          Expanded(
            child: ListView.builder(
              itemCount: itemList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(itemList[index].name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => (),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
