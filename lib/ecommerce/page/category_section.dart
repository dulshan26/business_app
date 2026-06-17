import 'package:flutter/material.dart';

class CategorySection extends StatelessWidget {
  const CategorySection({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = ["Electronics", "Car", "Home", "Accessories"];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: categories.map((e) => Chip(label: Text(e))).toList(),
      ),
    );
  }
}
