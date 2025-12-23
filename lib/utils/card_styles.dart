import 'package:flutter/material.dart';

class CardStyles {
  static const List<List<Color>> gradients = [
    // Tech (Blue/Purple)
    [Color(0xFF4facfe), Color(0xFF00f2fe)],
    // Creative (Orange/Pink)
    [Color(0xFFfa709a), Color(0xFFfee140)],
    // Finance (Green/Teal)
    [Color(0xFF43e97b), Color(0xFF38f9d7)],
    // Services (Purple/Red)
    [Color(0xFF667eea), Color(0xFF764ba2)],
    // Dark/Sleek
    [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
  ];

  static LinearGradient getGradient(int index) {
    final colors = gradients[index % gradients.length];
    return LinearGradient(
      colors: colors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static Color getContrastColor(int index) {
     return Colors.white;
  }

  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Tech':
        return Icons.code;
      case 'Finance':
        return Icons.account_balance;
      case 'Creative':
        return Icons.palette;
      case 'Services':
        return Icons.handshake;
      default:
        return Icons.business;
    }
  }
}
