// main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/cart_model.dart';
import 'pages/canteen_selection_page.dart';
import 'package:firebase_core/firebase_core.dart'; // Import
import 'firebase_options.dart'; // Import

void main() async {
  // Make main async
  WidgetsFlutterBinding.ensureInitialized(); // Required
  await Firebase.initializeApp(
    // Initialize Firebase
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (context) => CartModel(),
      child: const CanteenApp(),
    ),
  );
}

class CanteenApp extends StatelessWidget {
  const CanteenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amrita Canteen',
      theme: ThemeData(
        primaryColor: const Color(0xFF8A1038),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF8A1038),
          secondary: const Color(0xFFD32F2F),
        ),
        scaffoldBackgroundColor: Colors.grey[50],
        fontFamily: 'Poppins',
      ),
      home: const CanteenSelectionPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
