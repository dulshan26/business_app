import 'package:flutter/material.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      width: double.infinity,
      color: Colors.black,
      alignment: Alignment.center,
      child: const Text(
        "© 2026 My Store",
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
