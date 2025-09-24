import 'package:flutter/material.dart';

class MainPageNotifier extends ChangeNotifier {
  int selectedIndex = 0;

  void setIndex(int index) {
    if (index == selectedIndex) return;
    selectedIndex = index;
    notifyListeners();
  }
}
