import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// 🔹 Start or get existing chat using ticketId from ticket_available collection
  Future<String> startChatWithSellerFromTicket(String ticketId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("User not logged in");

    final buyerUid = currentUser.uid;

    // 🔹 Step 1: Get seller email from ticket_available
    final ticketDoc =
        await _firestore.collection('ticket_available').doc(ticketId).get();

    if (!ticketDoc.exists) {
      throw Exception("Ticket not found in Firestore.");
    }

    final sellerEmail = ticketDoc.data()?['uploaderEmail'];
    if (sellerEmail == null || sellerEmail.isEmpty) {
      throw Exception("Seller email missing in ticket document.");
    }

    // 🔹 Step 2: Find seller UID using their email
    final sellerQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: sellerEmail)
        .limit(1)
        .get();

    if (sellerQuery.docs.isEmpty) {
      throw Exception("Seller not found in Users collection.");
    }

    final sellerUid = sellerQuery.docs.first.id;

    // 🔹 Step 3: Generate chatId (consistent between both)
    final chatId = buyerUid.hashCode <= sellerUid.hashCode
        ? '$buyerUid-$sellerUid'
        : '$sellerUid-$buyerUid';

    final chatData = {
      'participants': [buyerUid, sellerUid],
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'ticketId': ticketId,
    };

    // 🔹 Step 4: Create/Update chat for both users
    await _firestore
        .collection('users')
        .doc(buyerUid)
        .collection('chats')
        .doc(chatId)
        .set(chatData, SetOptions(merge: true));

    await _firestore
        .collection('users')
        .doc(sellerUid)
        .collection('chats')
        .doc(chatId)
        .set(chatData, SetOptions(merge: true));

    return chatId;
  }
}
