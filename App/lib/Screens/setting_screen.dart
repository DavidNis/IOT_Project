import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  @override
  void initState() {
    super.initState();
    _auth.authStateChanges().listen((User? user) {
      setState(() {
        _user = user;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display welcome message at the top when signed in
            if (_user != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Text(
                  'Welcome back, ${_user?.displayName ?? 'User'}', // This fetches the displayName directly from Firebase
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            // Sign In/Sign Up or Sign Out button
            if (_user != null)
              ListTile(
                leading: Icon(Icons.exit_to_app),
                title: Text('Sign Out'),
                onTap: () async {
                  await _auth.signOut();
                  setState(() {});
                },
              )
            else
              ListTile(
                leading: Icon(Icons.login),
                title: Text('Sign In / Sign Up'),
                onTap: () {
                  _showAuthDialog();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showAuthDialog() {
    showDialog(
      context: context,
      builder: (context) => _AuthDialog(),
    );
  }
}

class _AuthDialog extends StatefulWidget {
  @override
  __AuthDialogState createState() => __AuthDialogState();
}

class __AuthDialogState extends State<_AuthDialog> {
  bool isSignUp = false;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Close the keyboard when tapping outside of the dialog
        FocusScope.of(context).unfocus();
      },
      child: AlertDialog(
        title: Text(isSignUp ? 'Sign Up' : 'Sign In'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Only show username field when signing up
            if (isSignUp)
              TextField(
                controller: usernameController,
                decoration: InputDecoration(labelText: 'Username'),
              ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            if (isSignUp)
              TextField(
                controller: confirmPasswordController,
                decoration: InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
              ),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSignUp ? () => _handleSignUp(context) : () => _handleSignIn(context),
                child: Text(isSignUp ? 'Sign Up' : 'Sign In'),
              ),
            ],
          ),
          Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  isSignUp = !isSignUp; // Toggle between Sign Up and Sign In
                });
              },
              child: Text(
                isSignUp
                    ? 'Already have an account? Sign In'
                    : "Don't have an account? Sign Up",
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSignIn(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signed in successfully as $email')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign in: ${e.toString()}')),
      );
    }
  }

  void _handleSignUp(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final username = usernameController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty || username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Set the display name to username
      await userCredential.user?.updateDisplayName(username);

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account created successfully for $email')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign up: ${e.toString()}')),
      );
    }
  }
}
