import 'package:flutter/material.dart';
import 'package:own/ecommerce/page/category_section.dart';
import 'package:own/ecommerce/page/contact_section.dart';
import 'package:own/ecommerce/page/feature_product.dart';
import 'package:own/ecommerce/page/footer_section.dart';
import 'package:own/ecommerce/page/header.dart';
import 'package:own/ecommerce/page/hero_banner.dart';
import 'package:own/ecommerce/page/leatet.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: const [
            HeaderSection(),
            HeroBanner(),
            CategorySection(),
            FeaturedProducts(),
            LatestProducts(),
            ContactSection(),
            FooterSection(),
          ],
        ),
      ),
    );
  }
}
