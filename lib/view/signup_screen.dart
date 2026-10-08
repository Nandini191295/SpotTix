import 'dart:io';
import 'package:dummy_firebase/controller/user_firebase_controller.dart';
import 'package:dummy_firebase/model/user_model.dart';
import 'package:dummy_firebase/view/login_screen.dart';
import 'package:dummy_firebase/widget/app_color.dart';
import 'package:dummy_firebase/widget/customize_snack_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:developer';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // 🔹 Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _mobileController = TextEditingController();

  // 🔹 Firebase + Custom Controller
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final UserFirestoreController _firestoreController = UserFirestoreController();

  // 🔹 Image file
  File? _selectedImage;

  // 🔹 Pick image from gallery
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  // 🔹 Dispose controllers
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  // 🔹 Register function
  Future<void> _registerUser(BuildContext context) async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final phone = _mobileController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty || phone.isEmpty) {
      customisedSnackbar().showSnackBar(context, "All fields are required.", bgColor: Colors.red);
      return;
    }

    if (password != confirmPassword) {
      customisedSnackbar().showSnackBar(context, "Passwords do not match.", bgColor: Colors.red);
      return;
    }

    try {
      // 🔹 Create Firebase User
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = userCredential.user!.uid;
      log("✅ User Registered: $email (UID: $uid)");

      log("✅ User Registered: ${userCredential.user?.email}");

      // 🔹 Upload Profile Image (if any)
      String profileUrl = '';
      if (_selectedImage != null) {
        profileUrl = await _firestoreController.uploadProfileImage(email, _selectedImage!) ?? '';
      }

      // 🔹 Create UserModel
      UserModel newUser = UserModel(
        uid:uid,
        name: name,
        email: email,
        phone: phone,
        profileUrl: profileUrl,
      );

      // 🔹 Save to Firestore
      await _firestoreController.saveUserToFirestore(newUser);

      customisedSnackbar().showSnackBar(context, "Registered successfully!", bgColor: Colors.green);

      // 🔹 Navigate to login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } on FirebaseAuthException catch (e) {
      customisedSnackbar().showSnackBar(context, e.message ?? "Registration failed.", bgColor: Colors.red);
    } catch (e) {
      customisedSnackbar().showSnackBar(context, "Unexpected error: $e", bgColor: Colors.red);
    }
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
                  // 🔹 Profile Image Picker
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 45,
                      backgroundColor: AppColors.purple.withOpacity(0.2),
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : null,
                      child: _selectedImage == null
                          ? const Icon(Icons.camera_alt, color: AppColors.purple, size: 32)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Create Account",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Join our marketplace",
                    style: TextStyle(color: AppColors.purple),
                  ),
                  const SizedBox(height: 20),

                  // 🔹 Input Fields
                  _buildTextField(_nameController, "Full Name", Icons.person_outline),
                  const SizedBox(height: 16),
                  _buildTextField(_emailController, "Email Address", Icons.email_outlined),
                  const SizedBox(height: 16),
                  _buildTextField(_passwordController, "Password", Icons.lock_outline, obscureText: true),
                  const SizedBox(height: 16),
                  _buildTextField(_confirmPasswordController, "Confirm Password", Icons.lock_outline, obscureText: true),
                  const SizedBox(height: 16),
                  _buildTextField(_mobileController, "Mobile Number", Icons.phone_outlined, keyboardType: TextInputType.phone),
                  const SizedBox(height: 20),

                  // 🔹 Register Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => _registerUser(context),
                    child: const Text("Create Account"),
                  ),
                  const SizedBox(height: 16),

                  // 🔹 Login Redirect
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? "),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          "Login",
                          style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 Reusable TextField builder
  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {bool obscureText = false, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
