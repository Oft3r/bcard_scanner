import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CardViewType {
  standard, // Regular card view
  compact, // Thin/List view
}

class UiProvider with ChangeNotifier {
  CardViewType _cardViewType = CardViewType.standard;

  CardViewType get cardViewType => _cardViewType;

  UiProvider() {
    _loadUiPreferences();
  }

  Future<void> _loadUiPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final viewTypeString = prefs.getString('card_view_type');

    if (viewTypeString == 'compact') {
      _cardViewType = CardViewType.compact;
    } else {
      _cardViewType = CardViewType.standard;
    }
    notifyListeners();
  }

  Future<void> setCardViewType(CardViewType type) async {
    _cardViewType = type;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    String typeStr = 'standard';
    if (type == CardViewType.compact) typeStr = 'compact';

    await prefs.setString('card_view_type', typeStr);
  }
}
