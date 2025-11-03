import 'package:flutter/material.dart';
import 'package:ics_application/screens/Splashscreen/splashscreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ICS Application',
      debugShowCheckedModeBanner: false, // Hides the debug banner
      theme: ThemeData(
        // You can define your app's theme here.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(), // Set SplashScreen as the home screen
    );
  }
}