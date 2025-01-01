import 'package:flutter/material.dart';

class IconButtonFeature extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive; // State of the button
  final VoidCallback onPressed;

  IconButtonFeature({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            shape: CircleBorder(),
            padding: EdgeInsets.all(16),
            backgroundColor: isActive ? Colors.blueAccent : Colors.grey[300], // Dynamic color
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.white : Colors.grey[700], // Icon color changes with state
            size: 24,
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.black : Colors.grey[700], // Label color changes with state
          ),
        ),
      ],
    );
  }
}