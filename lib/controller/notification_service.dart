import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔹 Send notification
  Future<void> sendNotification({
    required String title,
    required String message,
    required String icon,
    required String color,
  }) async {
    try {
      final currentUserEmail = _auth.currentUser?.email;
      if (currentUserEmail == null) return;

      await _firestore
          .collection("users")
          .doc(currentUserEmail)
          .collection("notifications")
          .add({
        "userId": currentUserEmail,
        "title": title,
        "message": message,
        "icon": icon,
        "color": color,
        "time": Timestamp.now(),
      });

      print("✅ Notification sent for $currentUserEmail");
    } catch (e) {
      print("❌ Failed to send notification: $e");
    }
  }

  /// 🔹 Stream notifications
  Stream<QuerySnapshot> getUserNotifications(String userEmail) {
    return _firestore
        .collection("users")
        .doc(userEmail)
        .collection("notifications")
        .orderBy("time", descending: true)
        .snapshots();
  }
}
