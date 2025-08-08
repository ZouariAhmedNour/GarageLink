
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget{
  final String text ;
  final VoidCallback? onPressed;
  final Color backgroundColor;
    final IconData? icon;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = const Color(0xFF6200EE),
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      icon: icon != null ? Icon(icon) : const SizedBox.shrink(), 
      label: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}