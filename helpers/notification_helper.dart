import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:licenta/services/notifications_service.dart'; 

class NotificationHelper {
  static Future<bool> _areNotificationsEnabled() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.data()?['notificationsEnabled'] ?? true;
  }

  static Future<void> sendFirestoreNotification({
    required String message,
  }) async {
    if (!await _areNotificationsEnabled()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': user.uid,
      'message': message,
      'timestamp': Timestamp.now(),
      'read': false,
    });
  }

  static Future<void> scheduleReminderNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (!await _areNotificationsEnabled()) return;

    await NotificationService.scheduleReminderNotification(
      id: id,
      title: title,
      body: body,
      scheduledTime: scheduledTime,
    );
  }
}
