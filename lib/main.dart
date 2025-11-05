import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:own/app/app.dart';
import 'package:own/credit_card/providers/balance_provider.dart';
import 'package:own/firebase/firebase_options.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => BalanceProvider()..listenToBalace(""),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
