import 'package:flutter/material.dart';

class UnreadCountProvider extends ChangeNotifier {
  int _unreadCount = 0;

  int get unreadCount => _unreadCount;

  void updateUnreadCount(int count) {
    _unreadCount = count;
    notifyListeners();
  }
}
