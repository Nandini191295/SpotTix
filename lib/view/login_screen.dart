import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dummy_firebase/controller/user_controller.dart';
import 'package:dummy_firebase/view/bottom_navigation_bar.dart';
import 'package:dummy_firebase/view/dummy_navi.dart';
import 'package:dummy_firebase/view/signup_screen.dart';
import 'package:dummy_firebase/widget/app_color.dart';
import 'package:dummy_firebase/widget/customize_snack_bar.dart';
import 'package:dummy_firebase/widget/sidebar_menu.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// 🔹 Login function separated for clarity
  Future<void> _login(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      customisedSnackbar().showSnackBar(
        context,
        "Enter valid credentials.",
        bgColor: Colors.red,
      );
      return;
    }

    try {
      // 🔹 Firebase login
      UserCredential userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      log("✅ User logged in: ${userCredential.user?.email}");

      // 🔹 Check if user is blocked
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists && userDoc.data()?['status'] == 'Blocked') {
        customisedSnackbar().showSnackBar(
          context,
          "Your account is blocked. Contact admin.",
          bgColor: Colors.red,
        );
        return;
      }

      customisedSnackbar().showSnackBar(
        context,
        "Login Successful!",
        bgColor: Colors.green,
      );

      // 🔹 Save local user data
      Map<String, dynamic> data = {
        'email': email,
        "loginFlag": true,
      };
      await UserController().setSharedPrefData(data);

      // 🔹 Navigate based on role
      if (email == "admin@gmail.com") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SidebarMenu()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => BottomNavigationScreen()),
        );
      }

      emailController.clear();
      passwordController.clear();
    } on FirebaseAuthException catch (e) {
      customisedSnackbar().showSnackBar(
        context,
        e.message ?? "Login failed.",
        bgColor: Colors.red,
      );
    } catch (e) {
      customisedSnackbar().showSnackBar(
        context,
        "Unexpected error: $e",
        bgColor: Colors.red,
      );
    }

    // 🔹 Replay the animation for button feedback
    _controller.reverse().then((_) => _controller.forward());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, AppColors.lightBackground],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      ScaleTransition(
                        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _controller,
                            curve: Curves.elasticOut,
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.purple,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.confirmation_num,
                              color: Colors.white, size: 40),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Welcome Back",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Sign in to continue",
                        style: TextStyle(color: AppColors.purple),
                      ),
                      const SizedBox(height: 20),

                      // 🔹 Email
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email_outlined),
                          labelText: "Email Address",
                          hintText: "your.email@example.com",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 🔹 Password
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline),
                          labelText: "Password",
                          hintText: "Enter your password",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // TODO: implement forgot password
                          },
                          child: const Text(
                            "Forgot password?",
                            style: TextStyle(color: AppColors.purple),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 🔹 Login Button
                      AnimatedScale(
                        duration: const Duration(milliseconds: 200),
                        scale: 1.0,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.purple,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 55),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => _login(context),
                          child: const Text("Login"),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 🔹 Signup Redirect
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account? "),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const SignupPage()),
                              );
                            },
                            child: const Text(
                              "Sign up",
                              style: TextStyle(
                                color: AppColors.purple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
