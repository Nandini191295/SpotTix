import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminWalletScreen extends StatefulWidget {
  const AdminWalletScreen({Key? key}) : super(key: key);

  @override
  State<AdminWalletScreen> createState() => _AdminWalletScreenState();
}

class _AdminWalletScreenState extends State<AdminWalletScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 Fetch sellerId from tickets_available using ticketId
  Future<String> _getSellerIdFromTicket(String ticketId) async {
    try {
      final doc =
          await _firestore.collection('tickets_available').doc(ticketId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['uploader'] ?? 'Unknown';
      }
    } catch (e) {
      debugPrint('Error fetching sellerId: $e');
    }
    return 'Unknown';
  }

  /// 🔹 Release payment to seller and deduct 2% commission
 /// 🔹 Release payment to seller and deduct 2% commission
Future<void> releasePayment(DocumentSnapshot doc) async {
  final data = doc.data() as Map<String, dynamic>;
  final double amount = (data['amount'] as num).toDouble();
  final String buyerId = data['buyerId'];
  final String ticketId = data['ticketId'];

  // Fetch seller email from tickets collection
  final String sellerEmail = await _getSellerIdFromTicket(ticketId);

  if (sellerEmail == 'Unknown') {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Seller not found for this ticket'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // 🔹 Step 1: Fetch seller UID from users collection using email
  String? sellerUid;
  try {
    final querySnapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: sellerEmail)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      sellerUid = querySnapshot.docs.first.id;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No user found for email: $sellerEmail'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
  } catch (e) {
    debugPrint("Error fetching seller UID: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error fetching seller UID: $e'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final double commission = amount * 0.02;
  final double sellerAmount = amount - commission;

  WriteBatch batch = _firestore.batch();

  try {
    final sellerRef = _firestore.collection('users').doc(sellerUid);
    final adminRef = _firestore.collection('AdminWalletSummary').doc('admin');

    // 🔹 Step 2: Update seller wallet balance
    batch.update(sellerRef, {
      'walletBalance': FieldValue.increment(sellerAmount),
    });

    // 🔹 Step 3: Add transaction to seller’s wallet history
    batch.update(sellerRef, {
      'transactions': FieldValue.arrayUnion([
        {
          'title': 'Ticket Sold - $ticketId',
          'amount': sellerAmount,
          'type': 'credit',
          'status': 'Completed',
          'buyerId': buyerId,
          'date': DateTime.now().toString(),
        }
      ])
    });

    // 🔹 Step 4: Update admin commission summary
    batch.set(adminRef, {
      'commissionEarned': FieldValue.increment(commission),
      'lastUpdated': DateTime.now().toString(),
    }, SetOptions(merge: true));

    // ✅ 🔹 Step 4.1: Add 2% income to Admin Wallet (for dashboard tracking)
    final adminDashboardRef =
        _firestore.collection('admin').doc(FirebaseAuth.instance.currentUser!.uid);
    batch.set(adminDashboardRef, {
      'income': FieldValue.increment(commission),
      'lastUpdated': DateTime.now().toString(),
    }, SetOptions(merge: true));

    // 🔹 Step 5: Update transaction status in AdminWallet
    batch.update(doc.reference, {
      'status': 'released',
      'releasedAt': DateTime.now().toString(),
      'commission': commission,
      'sellerEmail': sellerEmail,
      'sellerUid': sellerUid,
    });

    await batch.commit();

    // 🔹 Step 6: Send notification to seller
    await _firestore
        .collection('users')
        .doc(sellerUid)
        .collection('notifications')
        .add({
      'message':
          '₹${sellerAmount.toStringAsFixed(2)} has been released to your wallet for Ticket $ticketId.',
      'type': 'credit',
      'timestamp': DateTime.now().toString(),
      'status': 'unread',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '₹${sellerAmount.toStringAsFixed(2)} released to $sellerEmail successfully! '
          'Admin earned ₹${commission.toStringAsFixed(2)}',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    debugPrint("Error releasing payment: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error releasing payment: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
Future<Map<String, String?>> getBuyerSellerUIDs(String ticketId) async {
  final firestore = FirebaseFirestore.instance;

  // Step 1: Get buyerEmail & sellerEmail from AdminWallet
  final walletDoc = await firestore.collection('AdminWallet').doc(ticketId).get();
  if (!walletDoc.exists) {
    throw Exception("No wallet entry found for ticketId: $ticketId");
  }

  final buyerEmail = walletDoc['buyerEmail'];
  final sellerEmail = walletDoc['sellerEmail'];

  // Step 2: Query Users collection to get UIDs
  final buyerSnapshot = await firestore
      .collection('Users')
      .where('email', isEqualTo: buyerEmail)
      .limit(1)
      .get();

  final sellerSnapshot = await firestore
      .collection('Users')
      .where('email', isEqualTo: sellerEmail)
      .limit(1)
      .get();

  final buyerUid =
      buyerSnapshot.docs.isNotEmpty ? buyerSnapshot.docs.first['uid'] : null;
  final sellerUid =
      sellerSnapshot.docs.isNotEmpty ? sellerSnapshot.docs.first['uid'] : null;

  return {'buyerUid': buyerUid, 'sellerUid': sellerUid};
}


  /// 🔹 Hold payment
  Future<void> holdPayment(DocumentSnapshot doc) async {
    try {
      await _firestore.collection('AdminWallet').doc(doc.id).update({
        'status': 'on_hold',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment put on hold.'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🔹 Load Admin Wallet transactions
  Stream<QuerySnapshot> _loadPayments() {
    return _firestore
        .collection('AdminWallet')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Admin Wallet",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _loadPayments(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No transactions found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final status = data['status'] ?? 'pending';
              final double amount = (data['amount'] as num).toDouble();
              final String buyerId = data['buyerId'] ?? 'Unknown';
              final String ticketId = data['ticketId'] ?? 'Unknown';

              final double commission = amount * 0.02;
              final double sellerAmount = amount - commission;

              return FutureBuilder<String>(
                future: _getSellerIdFromTicket(ticketId),
                builder: (context, snapshot) {
                  final sellerId =
                      snapshot.hasData ? snapshot.data! : 'Loading...';

                  return Card(
                    color: Colors.deepPurple.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Ticket: $ticketId",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text("Buyer: $buyerId",
                              style: GoogleFonts.poppins(fontSize: 14)),
                          Text("Seller: $sellerId",
                              style: GoogleFonts.poppins(fontSize: 14)),
                          const SizedBox(height: 6),
                          Text("Amount: ₹$amount",
                              style: GoogleFonts.poppins(fontSize: 14)),
                          Text("Seller gets: ₹$sellerAmount",
                              style: GoogleFonts.poppins(fontSize: 14)),
                          Text(
                              "Admin commission: ₹${commission.toStringAsFixed(2)}",
                              style: GoogleFonts.poppins(fontSize: 14)),
                          Text("Status: $status",
                              style: GoogleFonts.poppins(fontSize: 14)),
                          const SizedBox(height: 10),
                          if (status == 'pending')
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () => releasePayment(docs[index]),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Release'),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: () => holdPayment(docs[index]),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Hold'),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}