import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(CaffeineTrackerApp());
}

class CaffeineTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Caffeine Tracker',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeScreen(),
    );
  }
}
