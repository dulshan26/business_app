import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:own/ecommerce/page/main_page/category_section.dart';
import 'package:own/ecommerce/page/main_page/footer_section.dart';
import 'package:own/ecommerce/page/main_page/header.dart';
import 'package:own/ecommerce/page/main_page/leatet.dart';
import 'package:own/getxpac/sales_item/item_controller.dart';

class SalesPage extends StatefulWidget {
  final String? initialCategory;

  const SalesPage({super.key, this.initialCategory});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  late final StockListController _stockController;

  @override
  void initState() {
    super.initState();
    _stockController = Get.isRegistered<StockListController>()
        ? Get.find<StockListController>()
        : Get.put(StockListController());
    _stockController.selectedCategory.value =
        widget.initialCategory?.toLowerCase() == 'all'
        ? ''
        : widget.initialCategory ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07152F),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const HeaderSection(activePage: 'shop'),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 38, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'THE TECHTONIC COLLECTION',
                        style: TextStyle(
                          color: Color(0xFF35D0BA),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Find your next smart device.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Browse smart things and everyday tech accessories.',
                        style: TextStyle(
                          color: Color(0xFFB7C7DE),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF102543),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFF203A60)),
                        ),
                        child: const CategorySection(),
                      ),
                      const SizedBox(height: 16),
                      Obx(() {
                        final category = _stockController
                            .selectedCategory
                            .value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            category.isEmpty ? 'All products' : category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      const LatestProducts(),
                    ],
                  ),
                ),
              ),
            ),
            const FooterSection(),
          ],
        ),
      ),
    );
  }
}
