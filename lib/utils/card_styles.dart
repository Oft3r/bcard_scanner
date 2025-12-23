import 'package:flutter/material.dart';

class CardStyles {
  // Professional Category Gradients
  static const Map<String, List<Color>> categoryGradients = {
    'Tech': [Color(0xFF141E30), Color(0xFF243B55)], // Deep Navy
    'Finance': [Color(0xFF134E5E), Color(0xFF71B280)], // Dark Teal/Green
    'Creative': [Color(0xFF2b5876), Color(0xFF4e4376)], // Purple/Blue
    'Services': [Color(0xFF4B79A1), Color(0xFF283E51)], // Steel Blue
    'Other': [Color(0xFF2C3E50), Color(0xFF4CA1AF)], // Dark Slate
  };

  static LinearGradient getGradientForCategory(String category) {
    final colors = categoryGradients[category] ?? categoryGradients['Other']!;
    return LinearGradient(
      colors: colors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // Legacy support if needed, or mapped to categories
  static LinearGradient getGradient(int index) {
    final keys = categoryGradients.keys.toList();
    final key = keys[index % keys.length];
    return getGradientForCategory(key);
  }

  static Color getContrastColor(int index) {
    return Colors.white;
  }

  static Color getContrastColorForCategory(String category) {
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
