import 'package:birthdays/components.dart';
import 'package:birthdays/homepage.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Birthdays',
      theme: MyTheme.lightTheme,
      darkTheme: MyTheme.darkTheme,
      home: const MyHomePage(title: 'Birthdays'),
    );
  }
}
