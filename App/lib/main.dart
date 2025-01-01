import 'package:flutter/material.dart';
import 'Screens/smart_ac_control.dart';

void main() {
  runApp(SmartACApp());
}

class SmartACApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SmartACControl(),
    );
  }
}