import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dummy_firebase/controller/chat_firebase.dart';
import 'package:dummy_firebase/widget/app_color.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PersonalChat extends StatefulWidget {
  final String ticketId;
  final String receiverEmail;
  final String eventName;
  final String eventDetails;

  const PersonalChat({
    super.key,
    required this.ticketId,
    required this.receiverEmail,
    required this.eventName,
    required this.eventDetails,
  });

  @override
  State<PersonalChat> createState() => _PersonalChatState();
}

class _PersonalChatState extends State<PersonalChat> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode focusNode = FocusNode();
  bool _isEmojiVisible = false;

  final _chatService = TicketChatFirestoreService();
  final _auth = FirebaseAuth.instance;

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final senderEmail = _auth.currentUser?.email;
    if (senderEmail == null) return;

    await _chatService.sendMessage(
      ticketId: widget.ticketId,
      senderEmail: senderEmail,
      receiverEmail: widget.receiverEmail,
      text: text,
    );

    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleEmojiPicker() {
    setState(() {
      _isEmojiVisible = !_isEmojiVisible;
      if (_isEmojiVisible) {
        focusNode.unfocus();
      } else {
        focusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserEmail = _auth.currentUser?.email ?? "";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.purple,
        elevation: 1,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.receiverEmail,
                    style: const TextStyle(color: Colors.white)),
                Row(
                  children: const [
                    Icon(Icons.verified, color: Colors.blue, size: 16),
                    SizedBox(width: 4),
                    Text("KYC Verified",
                        style:
                            TextStyle(fontSize: 12, color: Colors.white70)),
                    SizedBox(width: 8),
                    Icon(Icons.star, color: Colors.orange, size: 16),
                    Text("4.8",
                        style:
                            TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.purple.withOpacity(0.1), AppColors.lightBackground],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.eventName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: AppColors.purple)),
                Text(widget.eventDetails,
                    style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessagesStream(widget.ticketId, currentUserEmail),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No messages yet"));
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final isMe = msg['senderEmail'] == currentUserEmail;
                    final text = msg['text'] ?? '';
                    final time = (msg['timestamp'] as Timestamp?)?.toDate();

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.7),
                          decoration: BoxDecoration(
                            color: isMe ? AppColors.purple : AppColors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(12),
                              topRight: const Radius.circular(12),
                              bottomLeft: Radius.circular(isMe ? 12 : 0),
                              bottomRight: Radius.circular(isMe ? 0 : 12),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                text,
                                style: TextStyle(
                                  color: isMe ? AppColors.white : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                time != null
                                    ? "${time.hour}:${time.minute.toString().padLeft(2, '0')}"
                                    : "Now",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isMe
                                      ? AppColors.white70
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
          _isEmojiVisible ? _buildEmojiPicker() : const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.emoji_emotions, color: AppColors.purple),
            onPressed: _toggleEmojiPicker,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: focusNode,
              decoration: const InputDecoration(
                hintText: "Type a message...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: AppColors.purple),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return SizedBox(
      height: 250,
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) {
          _controller.text += emoji.emoji;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        },
      ),
    );
  }
}
