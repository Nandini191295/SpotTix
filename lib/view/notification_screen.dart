import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationScreen extends StatefulWidget {
  final String userEmail;
  const NotificationScreen({super.key, required this.userEmail});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.arrow_back),
                  ),
                  Text(
                    "Notifications",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  StreamBuilder<QuerySnapshot>(
                    // Fetch notification count from user's subcollection
                    stream: _firestore
                        .collection("users")
                        .doc(widget.userEmail)
                        .collection("notifications")
                        .snapshots(),
                    builder: (context, snapshot) {
                      int count = snapshot.data?.docs.length ?? 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.deepPurpleAccent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "$count",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Notifications List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  // Stream from user's subcollection
                  stream: _firestore
                      .collection("users")
                      .doc(widget.userEmail)
                      .collection("notifications")
                      .orderBy("time", descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final notifications = snapshot.data?.docs ?? [];

                    if (notifications.isEmpty) {
                      return Center(
                        child: Text(
                          "No notifications yet 💤",
                          style: GoogleFonts.poppins(
                              color: Colors.grey, fontSize: 14),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final data = notifications[index].data()
                            as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12.withOpacity(0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    _getColor(data["color"]).withOpacity(0.15),
                                radius: 22,
                                child: Icon(
                                  _getIcon(data["icon"]),
                                  color: _getColor(data["color"]),
                                  size: 22,
                                ),
                              ),
                              title: Text(
                                data["title"] ?? "Notification",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    data["message"] ?? "",
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey[700],
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatTime(data["time"]),
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: const Icon(
                                Icons.circle,
                                color: Colors.deepPurpleAccent,
                                size: 8,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String? iconName) {
    switch (iconName) {
      case "attach_money":
        return Icons.attach_money;
      case "chat_bubble_outline":
        return Icons.chat_bubble_outline;
      case "verified_outlined":
        return Icons.verified_outlined;
      case "local_offer_outlined":
        return Icons.local_offer_outlined;
      case "block":
        return Icons.block;
      default:
        return Icons.notifications_none;
    }
  }

  Color _getColor(String? colorName) {
    switch (colorName) {
      case "green":
        return Colors.green;
      case "purple":
        return Colors.purpleAccent;
      case "blue":
        return Colors.blueAccent;
      case "orange":
        return Colors.orangeAccent;
      case "red":
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return "";
    final date = timestamp.toDate();
    return "${date.hour.toString().padLeft(2,'0')}:${date.minute.toString().padLeft(2,'0')} | ${date.day}/${date.month}/${date.year}";
  }
}
