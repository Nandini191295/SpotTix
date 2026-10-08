import 'package:cloud_firestore/cloud_firestore.dart';

/// 💬 TicketChatFirestoreService
/// Handles all Firestore operations related to chat messages
/// between buyers and sellers for a specific ticket.
///
/// Firestore Structure:
/// ```
/// tickets_chats/{ticketId}/users/{userEmail}/messages/{messageId}
/// ```
class TicketChatFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 Get reference to a user’s chat document for a specific ticket
  DocumentReference<Map<String, dynamic>> getChatDoc(
      String ticketId, String userEmail) {
    return _firestore
        .collection('tickets_chats')
        .doc(ticketId)
        .collection('users')
        .doc(userEmail);
  }

  // 🔹 Get reference to messages subcollection
  CollectionReference<Map<String, dynamic>> getMessagesCollection(
      String ticketId, String userEmail) {
    return getChatDoc(ticketId, userEmail).collection('messages');
  }

  // 🔹 Send message between two users for a specific ticket
  Future<void> sendMessage({
    required String ticketId,
    required String senderEmail,
    required String receiverEmail,
    required String text,
  }) async {
    try {
      final messageData = {
        'senderEmail': senderEmail,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Add message to sender's and receiver's message lists (mirrored)
      await getMessagesCollection(ticketId, senderEmail).add(messageData);
      await getMessagesCollection(ticketId, receiverEmail).add(messageData);

      // Update chat summary (metadata) for both sender and receiver
      final chatMeta = {
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'ticketId': ticketId,
      };

      await getChatDoc(ticketId, senderEmail).set(
        {...chatMeta, 'otherUser': receiverEmail},
        SetOptions(merge: true),
      );

      await getChatDoc(ticketId, receiverEmail).set(
        {...chatMeta, 'otherUser': senderEmail},
        SetOptions(merge: true),
      );

      print("✅ Message sent successfully between $senderEmail and $receiverEmail");
    } catch (e) {
      print("❌ Error sending message: $e");
    }
  }

  // 🔹 Stream all messages for a ticket between two users
  Stream<QuerySnapshot<Map<String, dynamic>>> getMessagesStream(
      String ticketId, String userEmail) {
    return getMessagesCollection(ticketId, userEmail)
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // 🔹 Stream all chat summaries for a given user (buyer or seller)
  Stream<QuerySnapshot<Map<String, dynamic>>> getUserChats(String userEmail) {
    return _firestore
        .collectionGroup('users')
        .where(FieldPath.documentId, isEqualTo: userEmail)
        .snapshots();
  }

  // 🔹 Delete chat (and all its messages) between two users
  Future<void> deleteChat(String ticketId, String user1, String user2) async {
    try {
      // Delete messages for both users
      final messagesUser1 = await getMessagesCollection(ticketId, user1).get();
      for (var doc in messagesUser1.docs) {
        await doc.reference.delete();
      }
      await getChatDoc(ticketId, user1).delete();

      final messagesUser2 = await getMessagesCollection(ticketId, user2).get();
      for (var doc in messagesUser2.docs) {
        await doc.reference.delete();
      }
      await getChatDoc(ticketId, user2).delete();

      print("🗑️ Chat deleted successfully between $user1 and $user2 for ticket $ticketId");
    } catch (e) {
      print("❌ Error deleting chat: $e");
    }
  }
}
