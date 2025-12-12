import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'views/navigation/bottom_nav_screen.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CinemaTick',
      theme: ThemeData(useMaterial3: true, primarySwatch: Colors.blue),
      home: const BottomNavScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
