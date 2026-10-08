import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dummy_firebase/widget/app_color.dart';

class AdminUserScreen extends StatefulWidget {
  const AdminUserScreen({super.key});

  @override
  State<AdminUserScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<AdminUserScreen> {
  String adminName = "";
  int totalUsers = 0;
  int totalVendors = 0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCounts();
  }

  Future<void> fetchCounts() async {
    try {
      final usersSnap =
          await FirebaseFirestore.instance.collection('users').get();
      final vendorsSnap =
          await FirebaseFirestore.instance.collection('vendors').get();

      setState(() {
        totalUsers = usersSnap.docs.length;
        totalVendors = vendorsSnap.docs.length;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.purple,
        title: const Text(
          "Dashboard",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<DocumentSnapshot>(
              // ✅ live listener to admin income
              stream: FirebaseFirestore.instance
                  .collection('admin')
                  .doc(currentUser!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data =
                    snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final totalIncome = (data['income'] ?? 0).toDouble();
                adminName = data['name'] ?? 'Admin';

                return RefreshIndicator(
                  onRefresh: fetchCounts,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome back, $adminName 👋",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Dashboard Cards
                        GridView.count(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.2,
                          children: [
                            _buildDashboardCard(
                              icon: Icons.attach_money,
                              title: "Total Income",
                              value: "₹${totalIncome.toStringAsFixed(2)}",
                              color: Colors.green.shade400,
                            ),
                            _buildDashboardCard(
                              icon: Icons.people,
                              title: "Users",
                              value: "$totalUsers",
                              color: Colors.blue.shade400,
                            ),
                            _buildDashboardCard(
                              icon: Icons.storefront,
                              title: "Vendors",
                              value: "$totalVendors",
                              color: Colors.deepPurple.shade400,
                            ),
                            _buildDashboardCard(
                              icon: Icons.analytics,
                              title: "Performance",
                              value: "${(totalVendors * 10) + totalUsers} pts",
                              color: Colors.orange.shade400,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 6,
            spreadRadius: 1,
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 38),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
