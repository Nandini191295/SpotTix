import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dummy_firebase/controller/user_firebase_controller.dart';
import 'package:dummy_firebase/model/user_model.dart';
import 'package:dummy_firebase/view/Ticket_sold_profile.dart';
import 'package:dummy_firebase/view/aboutus.dart';
import 'package:dummy_firebase/view/login_screen.dart';

import 'package:dummy_firebase/view/ticket_purchased_profile.dart';
import 'package:dummy_firebase/widget/app_color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  UserModel? currentUser;
bool isLoading = true;
final FirebaseAuth _auth = FirebaseAuth.instance;
final UserFirestoreController _firestoreController = UserFirestoreController();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
      _fetchCurrentUser();
    });
    
  }
//   Future<void> _fetchCurrentUser() async {
//   try {
//     final user = _auth.currentUser;
//     if (user != null) {
//       final docSnapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .get();

//       if (docSnapshot.exists) {
//         final userData = docSnapshot.data()!;
//         final userModel = UserModel.fromMap(userData);

//         // 🟢 Safely count purchased/sold tickets from stored maps
//         final purchasedCount = (userData['purchasedTickets'] as Map?)?.length ?? 0;
//         final soldCount = (userData['soldTickets'] as Map?)?.length ?? 0;

//        setState(() {
//   currentUser = userModel.copyWith(
//     ticketsBoughtCount: purchasedCount,
//     ticketsSoldCount: soldCount,
//   );
// });

//         print("✅ User data fetched successfully with counts: bought=$purchasedCount, sold=$soldCount");
//       }
//     }
//   } catch (e) {
//     print("❌ Error fetching user data: $e");
//   }
// }

Future<void> _fetchCurrentUser() async {
  setState(() => isLoading = true);

  try {
    // Get current user's UID from Firebase Auth
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      print("⚠ No logged-in user found.");
      return;
    }

    // Fetch user data from Firestore using your controller
    final userData = await _firestoreController.getUserByUid(uid);

    if (userData != null) {
      setState(() {
        currentUser = userData;
      });
      print("✅ User data fetched: ${userData.toMap()}");
    } else {
      print("⚠ User document not found in Firestore.");
    }
  } catch (e) {
    print("❌ Error fetching user: $e");
  } finally {
    setState(() => isLoading = false);
  }
}


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  /// 🔹 Pick image and upload to Firebase Storage
  Future<void> _pickAndUploadProfileImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      final email = currentUser?.email;
      if (email == null) return;

      // Upload to Firebase Storage + update Firestore
      final downloadUrl =
          await _firestoreController.uploadProfileImage(email, file);

      if (downloadUrl != null) {
        setState(() {
          currentUser = currentUser!.copyWith(profileUrl: downloadUrl);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Profile picture updated")),
        );
      }
    } catch (e) {
      print("Error uploading profile image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FB),
      // AppBar added from the image
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Profile",
          style: TextStyle(
            color: AppColors.purple,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 20.0),
            child: Text(
              "Manage your account",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        // Set background color to lightBackground as seen in the image
        color:  const Color(0xFFF7F6FB),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Profile Header
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white, // Changed to solid white background
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                             GestureDetector(
                              onTap: _pickAndUploadProfileImage,
                              child: CircleAvatar(
                                radius: 35,
                                backgroundColor: AppColors.purple,
                                backgroundImage: (currentUser?.profileUrl != null &&
                                        currentUser!.profileUrl.isNotEmpty)
                                    ? NetworkImage(currentUser!.profileUrl)
                                    : null,
                                child: (currentUser?.profileUrl == null ||
                                        currentUser!.profileUrl.isEmpty)
                                    ? Text(
                                        currentUser?.name
                                                .substring(0, 1)
                                                .toUpperCase() ??
                                            '?',
                                        style: const TextStyle(
                                          fontSize: 32,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                      
                                  children: [
                                    Text(
                                      // Reverted to original name (John Doe structure from image)
                                      currentUser?.name ?? "Loading...",
                                      style: TextStyle(
                                        color: AppColors.purple,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis, // prevent overflow
                                      maxLines: 1,
                                    ),
                                    const SizedBox(width: 8),
                                    // Verified Badge
                                    // Container(
                                    //   padding: const EdgeInsets.symmetric(
                                    //       horizontal: 8, vertical: 4),
                                    //   decoration: BoxDecoration(
                                    //     color: Colors.green.withOpacity(0.1),
                                    //     borderRadius: BorderRadius.circular(10),
                                    //   ),
                                    //   child: const Row(
                                    //     children: [
                                    //       Icon(Icons.check_circle,
                                    //           color: Colors.green, size: 15),
                                    //       SizedBox(width: 4),
                                    //       Text(
                                    //         "Verified",
                                    //         style: TextStyle(
                                    //             color: Colors.green,
                                    //             fontSize: 12),
                                    //       ),
                                    //     ],
                                    //   ),
                                    // ),
                                    if (currentUser?.isKycVerified == true)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.green, size: 15),
                                            SizedBox(width: 4),
                                            Text(
                                              "Verified",
                                              style: TextStyle(color: Colors.green, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        
                                      ),

                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  // Reverted to original email
                                  currentUser?.email ?? "Loading...",
                                  style: TextStyle(
                                    color: Colors.grey.withOpacity(0.85),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Stats row from the image
                         Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                          
                            _buildStatColumn(currentUser?.walletBalance.toStringAsFixed(2) ?? '0.0', "Wallet"),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Edit Profile Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // Handle Edit Profile
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.purple.withOpacity(0.1),
                              foregroundColor: AppColors.purple,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              "Edit Profile",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Animated Cards
                  // My Tickets (Selling)
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context){
                        return UploadedTicketsScreen();
                      }));
                    },
                    child: _buildAnimatedCard(
                      icon: Icons.confirmation_num_outlined,
                      title: "My Tickets",
                      subtitle: "Tickets you're selling",
                      color: AppColors.purple,
                      delay: 0,
                      trailingText: "12",
                    ),
                  ),
                  // Purchased Tickets
                 
                  // Settings
                  GestureDetector(
                    onTap:(){
                        Navigator.of(context).push(MaterialPageRoute(builder: (context){
                          return PurchasedTicketsScreen();
                        }));
                    },
                    child: _buildAnimatedCard(
                      icon: Icons.settings,
                      title: "Tickets Purchase",
                      subtitle: "tickets you purchased.",
                      color: AppColors.purple,
                      delay: 200,
                    ),
                  ),
                   GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context){
                        return AboutUsScreen();
                      }));
                    },
                    child: _buildAnimatedCard(
                      icon: Icons.info_outline,
                      title: "About Us",
                      subtitle: "Learn more about us — the team behind Spottix!",
                      color: Colors.green, // Changed color to differentiate
                      delay: 100,
                  
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Logout Button
                  GestureDetector(
                    onTap: () {
                      //Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ChatScreen()));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: AppColors.purple.withOpacity(0.15),
                                child: const Icon(Icons.logout,
                                    color: AppColors.purple, size: 28),
                              ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap:()async{
                                  await FirebaseAuth.instance.signOut(); // 🔹 Sign out from Firebase

                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(builder: (context) => const LoginPage()),
                                      (route) => false, // 🔹 Removes all previous routes
                                    );
                                },
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Logout",
                                      style: TextStyle(
                                          color: AppColors.purple,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Sign out of your account",
                                      style: TextStyle(
                                        color: Color.fromRGBO(118, 117, 117, 1),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Icon(Icons.chevron_right, color: AppColors.purple),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method for the stats column
  static Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.purple,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // Animated Card Widget (modified to accept trailingText)
  Widget _buildAnimatedCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required int delay,
    String? trailingText, // Added optional trailing text
  }) {
    final animation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(delay / 300, 1.0, curve: Curves.easeOut),
      ),
    );

    return SlideTransition(
      position: animation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        color: AppColors.purple,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color.fromRGBO(118, 117, 117, 1),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (trailingText != null) // Conditionally show trailing text/count
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    trailingText,
                    style: TextStyle(color: color, fontSize: 12),
                  ),
                ),
              ),
            const Icon(Icons.chevron_right, color: AppColors.purple),
          ],
        ),
      ),
    );
  }
}