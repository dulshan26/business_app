// ignore: file_names
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:own/login/main_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Own',
      debugShowCheckedModeBanner: false,
      home: MainPage(),
    );
  }
}
//meka GetX walata use karanne gatta eka normall eka oni nm app.dart eka balanne