import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:own/getxpac/sales_item/item_controller.dart';

class CategorySection extends StatelessWidget {
  const CategorySection({super.key});

  @override
  Widget build(BuildContext context) {
    // 🌟 FIX: Hosting වලදී crash නොවෙන්න, register වෙලා නැත්නම් put කරනවා, තිබ්බොත් find කරනවා
    final StockListController controller =
        Get.isRegistered<StockListController>()
        ? Get.find<StockListController>()
        : Get.put(StockListController());

    final categories = ["All", "Smart Things", "Accessories", "Other Items"];

    return Padding(
      // Padding එක පොඩ්ඩක් web එකටත් ලස්සන වෙන්න adjust කළා
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Obx(() {
        // Controller එක තාම load වෙනවා නම් හිස් space එකක් පෙන්වන්නේ නැතුව loader එකක් දානවා
        if (controller.isLoading.value && controller.products.isEmpty) {
          return const SizedBox(
            height: 40,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        return Wrap(
          spacing: 12,
          runSpacing: 10,
          alignment: WrapAlignment.start, // Chips වමේ ඉඳන් ලස්සනට පෙළගස්වන්න
          children: categories.map((cat) {
            final isSelected = cat == "All"
                ? controller.selectedCategory.value.isEmpty
                : controller.selectedCategory.value == cat;

            return ChoiceChip(
              label: Text(
                cat,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF07152F)
                      : const Color(0xFFD8E4F4),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13, // Standard font size for cross-platform
                ),
              ),
              selected: isSelected,
              selectedColor: const Color(0xFF35D0BA),
              backgroundColor: const Color(0xFF17345C),
              onSelected: (bool selected) {
                controller.changeCategory(cat);
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF35D0BA)
                      : const Color(0xFF355074),
                ),
              ),
              showCheckmark: false,
            );
          }).toList(),
        );
      }),
    );
  }
}
