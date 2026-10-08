import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageController {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload profile picture and return the download URL
  Future<String> uploadProfilePic(String email, File imageFile) async {
    try {
      final ref = _storage.ref().child('profile_pics/$email.jpg');
      await ref.putFile(imageFile);
      String downloadUrl = await ref.getDownloadURL();
      print("✅ Profile pic uploaded: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      print("Error uploading profile pic: $e");
      return '';
    }
  }
}
