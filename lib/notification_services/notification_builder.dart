import 'dart:async';

class NotificationService {
  final StreamController<List<Map<String, dynamic>>> _notificationsController =
  StreamController<List<Map<String, dynamic>>>();

  Stream<List<Map<String, dynamic>>> get notificationsStream =>
      _notificationsController.stream;

  void dispose() {
    _notificationsController.close();
  }

  void updateNotifications(List<Map<String, dynamic>> notifications) {
    _notificationsController.add(notifications);
  }
}
