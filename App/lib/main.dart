import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
//import 'Screens/login_screen.dart'; // Import the LoginScreen
import 'Screens/smart_ac_control.dart'; // Import the SmartACControl screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart AC',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false, // Remove the debug banner
      //home: LoginScreen(),
      home: SmartACControl(), // Set LoginScreen as the home screen
    );
  }
}
