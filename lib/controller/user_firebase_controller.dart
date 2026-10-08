import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../model/user_model.dart';

class UserFirestoreController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// 🔹 Save or update user data
  Future<void> saveUserToFirestore(UserModel user) async {
    try {
     await _firestore
    .collection('users')
    .doc(user.uid) // ✅ use uid instead of email
    .set(user.toMap(), SetOptions(merge: true));
    print("✅ User data saved for ${user.email}");

    } catch (e) {
      print("❌ Error saving user: $e");
    }
  }

  /// 🔹 Get user by UID
  Future<UserModel?> getUserByUid(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) return UserModel.fromMap(doc.data()!);
      return null;
    } catch (e) {
      print("❌ Error fetching user: $e");
      return null;
    }
  }

  /// 🔹 Get user by email
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final doc = await _firestore.collection('users').doc(email).get();
      if (doc.exists) return UserModel.fromMap(doc.data()!);
      return null;
    } catch (e) {
      print("❌ Error fetching user: $e");
      return null;
    }
  }

  /// 🔹 Upload Profile Image
  Future<String?> uploadProfileImage(String email, File imageFile) async {
    try {
      final ref = _storage.ref().child('user_profiles/$email.jpg');
      final uploadTask = await ref.putFile(imageFile);
      final url = await uploadTask.ref.getDownloadURL();

      await _firestore.collection('users').doc(email).update({
        'profileUrl': url,
      });

      print("✅ Profile image updated for $email");
      return url;
    } catch (e) {
      print("❌ Error uploading profile image: $e");
      return null;
    }
  }

  /// 🔹 Get all users
  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    } catch (e) {
      print("❌ Error fetching all users: $e");
      return [];
    }
  }
}
