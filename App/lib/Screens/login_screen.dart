import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'smart_ac_control.dart'; // Import the SmartACControl screen

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController(); // Separate controller for confirm password
  bool isSignUp = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // gradient background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color.fromARGB(255, 88, 166, 255)!, const Color.fromARGB(255, 189, 222, 249)!],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo or App name
                  Icon(
                    Icons.account_circle,
                    size: 120,
                    color: Colors.white,
                  ),
                  SizedBox(height: 20),
                  // Heading Text
                  Text(
                    isSignUp ? 'Create Account' : 'Sign In',
                    style: TextStyle(
                      fontSize: 30,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  // Username TextField (only visible for Sign Up)
                  if (isSignUp)
                    _buildTextField(
                      controller: _usernameController,
                      label: 'Username',
                      icon: Icons.person,
                    ),
                  // Email TextField
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  // Password TextField
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Password',
                    icon: Icons.lock,
                    obscureText: true,
                  ),
                  // Confirm Password TextField (only visible for Sign Up)
                  if (isSignUp)
                    _buildTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password',
                      icon: Icons.lock,
                      obscureText: true,
                    ),
                  SizedBox(height: 30),
                  // Sign In/Sign Up Button
                  _buildAuthButton(context),
                  SizedBox(height: 20),
                  // Switch between Sign Up and Sign In
                  _buildSwitchAuthMode(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // TextField Widget for input fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(color: Colors.black),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white),
          labelText: label,
          labelStyle: TextStyle(color: Colors.white),
          filled: true,
          fillColor: Colors.white.withOpacity(0.7),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // Sign In / Sign Up Button
  Widget _buildAuthButton(BuildContext context) {
    return ElevatedButton(
      onPressed: isSignUp ? _signUp : _signIn,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 5,
      ),
      child: Text(
        isSignUp ? 'Sign Up' : 'Sign In',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Switch between Sign In and Sign Up
  Widget _buildSwitchAuthMode() {
    return TextButton(
      onPressed: () {
        setState(() {
          isSignUp = !isSignUp;
        });
      },
      child: Text(
        isSignUp
            ? 'Already have an account? Sign In'
            : "Don't have an account? Sign Up",
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  // Handle Sign In
  void _signIn() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill in all fields')),
        );
      }
      return;
    }

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SmartACControl()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = 'The email does not exist. Please check it or sign up.';
      } else if (e.code == 'wrong-password') {
        message = 'Check your email and password';
      } else if (e.code == 'invalid-credential' || e.code == 'invalid-verification-code' || e.code == 'invalid-verification-id') {
        message = 'Please check your email and password';
      } else {
        message = 'Failed to sign in: ${e.message}';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign in: $e')),
        );
      }
    }
  }

  // Handle Sign Up
  void _signUp() async {
    try {
      final email = _emailController.text;
      final password = _passwordController.text;
      final confirmPassword = _confirmPasswordController.text;
      final username = _usernameController.text;

      if (email.isEmpty || password.isEmpty || username.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please fill in all fields')),
          );
        }
        return;
      }

      if (password != confirmPassword) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Passwords do not match')),
          );
        }
        return;
      }

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Set the display name to username
      await userCredential.user?.updateDisplayName(username);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SmartACControl()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message = 'Password should be at least 6 characters';
      } else {
        message = 'Failed to sign up: ${e.message}';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign up: $e')),
        );
      }
    }
  }
}