import 'package:flutter/material.dart';

class AddPieceButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AddPieceButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF50C878),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
        ),
        icon: const Icon(Icons.add, size: 18),
        label: const Text(
          'Ajouter la pièce',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}