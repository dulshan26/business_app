import 'package:flutter/material.dart';

class ResponsibleLayouts extends StatelessWidget {
  final Widget mobileBody;
  final Widget desktopBody;
  const ResponsibleLayouts({
    super.key,
    required this.mobileBody,
    required this.desktopBody,
  });

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width > 600;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return desktopBody;
        } else {
          return mobileBody;
        }
      },
    );
  }
}
