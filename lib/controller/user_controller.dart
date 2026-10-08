import 'package:shared_preferences/shared_preferences.dart';

class UserController {
  String email = "";
  String password = "";
  bool isUserLoggedIn = false;

  /// 🔹 Save login data locally
  Future<void> setSharedPrefData(Map<String, dynamic> obj) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("email", obj['email']);
    await prefs.setBool("isUserLoggedIn", obj['loginFlag']);
  }

  /// 🔹 Retrieve saved session data
  Future<void> getSharedPrefData() async {
    final prefs = await SharedPreferences.getInstance();
    email = prefs.getString("email") ?? "";
    password = prefs.getString("password") ?? "";
    isUserLoggedIn = prefs.getBool("isUserLoggedIn") ?? false;
  }

  /// 🔹 Clear session data
  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print("🧹 Cleared local user session");
  }
}
