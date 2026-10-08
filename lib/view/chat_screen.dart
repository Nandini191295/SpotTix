import 'package:dummy_firebase/view/ai_chat.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<DocumentSnapshot> _chats = [];

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text("Not logged in"));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: const Text(
          "Messages",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.email)
            .collection('ticket_ai_chats')
            .orderBy('lastUpdated', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Something went wrong 😕",
                style: TextStyle(color: Colors.red.shade400),
              ),
            );
          }

          final chats = snapshot.data?.docs ?? [];
          if (chats.isEmpty) {
            return const Center(
              child: Text(
                "No messages yet",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          _chats = chats;

          return AnimatedList(
            key: _listKey,
            initialItemCount: _chats.length,
            itemBuilder: (context, index, animation) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutExpo),
                ),
                child: FadeTransition(
                  opacity: animation,
                  child: _buildChatCard(context, _chats[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildChatCard(BuildContext context, DocumentSnapshot chatDoc) {
    final chat = chatDoc.data() as Map<String, dynamic>;
    final currentUser = FirebaseAuth.instance.currentUser!;
    final lastUpdated = (chat['lastUpdated'] as Timestamp?)?.toDate();
    final timeString = lastUpdated != null
        ? DateFormat.jm().format(lastUpdated)
        : "Now";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => TicketAIChatScreen(
              ticketInfo: {
                'title': chat['ticketTitle'] ?? 'Untitled Ticket',
                'price': chat['price'] ?? 0,
              },
              ticketId: chatDoc.id,
              userEmail: currentUser.email!,
            ),
            transitionsBuilder: (_, anim, __, child) {
              final tween = Tween(begin: const Offset(1, 0), end: Offset.zero)
                  .chain(CurveTween(curve: Curves.easeOutCubic));
              return SlideTransition(position: anim.drive(tween), child: child);
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Hero(
              tag: chat['ticketTitle'] ?? chatDoc.id,
              child: CircleAvatar(
                radius: 28,
                backgroundColor: const Color.fromRGBO(138, 0, 255, 1),
                child: Text(
                  (chat['ticketTitle']?.isNotEmpty ?? false)
                      ? chat['ticketTitle'][0].toUpperCase()
                      : "?",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat['ticketTitle'] ?? "Ticket",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chat['lastMessage'] ?? "No messages yet",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              timeString,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
