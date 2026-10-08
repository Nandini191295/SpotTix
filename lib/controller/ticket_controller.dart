import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dummy_firebase/model/ticket_model_class.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TicketController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream for tickets uploaded by the current user
  Stream<List<TicketModel>> streamUploadedTickets() {
    final currentUserEmail = _auth.currentUser?.email ?? '';
    return _firestore
        .collection('tickets_available')
        .where('uploader', isEqualTo: currentUserEmail)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TicketModel.fromMap(doc.data())).toList());
  }

  // Stream for tickets purchased by the current user
  Stream<List<TicketModel>> streamPurchasedTickets() {
    final currentUserEmail = _auth.currentUser?.email ?? '';
    return _firestore
        .collection('tickets_available')
        .where('buyerId', isEqualTo: currentUserEmail)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TicketModel.fromMap(doc.data())).toList());
  }
}