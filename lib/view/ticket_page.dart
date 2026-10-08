import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dummy_firebase/controller/notification_service.dart';
import 'package:dummy_firebase/model/ticket_model_class.dart';
import 'package:dummy_firebase/view/UPI_sucessfull_screen.dart';
import 'package:dummy_firebase/view/ai_chat.dart';
import 'package:dummy_firebase/view/ticket_chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TicketPage extends StatefulWidget {
  final TicketModel ticket;
  final double walletBalance;
  final String buyerEmail; // pass logged in user email

  const TicketPage({
    super.key,
    required this.ticket,
    required this.walletBalance,
    required this.buyerEmail,
  });

  @override
  State<TicketPage> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketPage> {
  final Color primaryColor = const Color(0xFF8A00FF);
  final Color verifiedColor = const Color(0xFF1EA322);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  double walletBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadWalletBalance();
  }

  Future<void> _loadWalletBalance() async {
    final userId = _auth.currentUser!.uid;
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      final data = userDoc.data()!;
      setState(() {
        walletBalance = (data['walletBalance'] ?? 0).toDouble();
      });
    }
  }

  Future<void> _showPaymentOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: 220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Select Payment Method",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _payWithWallet(),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8A00FF)),
              child: const Text(
                "Pay with Wallet",
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _payWithUPI(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text(
                "Pay with UPI",
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

Future<void> _payWithWallet() async {
  Navigator.pop(context); // Close bottom sheet
  double price = double.tryParse(widget.ticket.price.toString()) ?? 0;

  final user = _auth.currentUser!;
  final userRef = _firestore.collection('users').doc(user.uid);
  final userDoc = await userRef.get();

  final rawBalance = userDoc.data()?['walletBalance'];
  double latestBalance = 0;
  if (rawBalance is num) {
    latestBalance = rawBalance.toDouble();
  } else if (rawBalance is String) {
    latestBalance = double.tryParse(rawBalance) ?? 0;
  }

  if (latestBalance < price) {
    _showMessage("❌ Insufficient wallet balance!");
    return;
  }

  final ticketRef = _firestore.collection('tickets_available').doc(widget.ticket.id);
  final ticketSnap = await ticketRef.get();

  if (!ticketSnap.exists) {
    _showMessage("❌ Ticket not found!");
    return;
  }

  final ticketData = ticketSnap.data()!;
  if (ticketData['status'] == 'sold') {
    _showMessage("🚫 This ticket is already sold!");
    return;
  }

  final sellerId = ticketData['seller'] ?? ''; // assuming you store seller email/id

  // Buyer transaction entry
  final buyerTx = {
    "title": "Ticket Purchase - ${widget.ticket.title}",
    "amount": price,
    "type": "debit",
    "status": "Completed",
    "date": DateTime.now().toString().split(" ")[0],
    "time": TimeOfDay.now().format(context),
  };

  try {
    // 🔹 1. Deduct amount from buyer wallet
    await userRef.update({
      'walletBalance': FieldValue.increment(-price),
      'transactions': FieldValue.arrayUnion([buyerTx]),
    });

    // 🔹 2. Mark ticket as sold
    await ticketRef.update({
      'status': 'sold',
      'buyerId': user.email,
    });

    // 🔹 3. Create Admin Wallet entry
    final double commission = price * 0.02; // 2%
    final double sellerAmount = price - commission;

    await _firestore.collection('AdminWallet').add({
      'buyerId': user.email,
      'sellerId': sellerId,
      'ticketId': widget.ticket.id,
      'amount': price,
      'commission': commission,
      'sellerAmount': sellerAmount,
      'status': 'pending',
      'createdAt': Timestamp.now(),
    });

    _showMessage("✅ Payment Successful!!!!!");

  } catch (e) {
    _showMessage("❌ Error: ${e.toString()}");
  }
}




  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessScreen(String message) {
    // You can navigate to your success screen here
  }

  Future<void> _payWithUPI() async {
    Navigator.pop(context); // Close the bottom sheet
    double price = double.tryParse(widget.ticket.price) ?? 0;

    await Future.delayed(const Duration(seconds: 1));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Payment Status"),
        content: Text("UPI Payment of ₹$price Successful!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close alert dialog
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentSuccessScreen(
                    message: "PhonePe Transaction Successful!",
                    ticket: widget.ticket,
                  ),
                ),
              );
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🔹 Determine category image
    String imagePath;
    switch ((widget.ticket.category ?? "").toLowerCase()) {
      case "concert":
        imagePath = "asset/concert.jpg";
        break;
      case "bus":
        imagePath = "asset/bus.jpg";
        break;
      case "movie":
        imagePath = "asset/cinema.jpeg";
        break;
      case "train":
        imagePath = "asset/train.jpeg";
        break;
      default:
        imagePath = "asset/default.jpeg";
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.ticket.title,
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black)),
            Text("Review before purchase",
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.purpleAccent)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(20)),
                  child: Image.asset(
                    imagePath,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.verified, color: verifiedColor, size: 16),
                        const SizedBox(width: 4),
                        Text("AI Verified",
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: verifiedColor)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.ticket.title,
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600)),
                      Text(widget.ticket.category,
                          style: GoogleFonts.poppins(
                              color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),

            // Ticket Details Card
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(Icons.calendar_today_rounded, "Date & Time",
                        "${widget.ticket.date} • ${widget.ticket.time}"),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                        Icons.location_on_rounded, "Venue", widget.ticket.venue),
                    const SizedBox(height: 10),
                    _buildDetailRow(Icons.chair, "Seat", widget.ticket.seat),
                  ],
                ),
              ),
            ),

            // Verified Ticket Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, const Color(0xFFB266FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("AI Verified Ticket",
                        style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                    const SizedBox(height: 6),
                    Text(
                      "This ticket has been scanned and verified by our AI-based authentication system.",
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: Colors.white70, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),

            // Price + Buy Now Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Total Price",
                                style: GoogleFonts.poppins(
                                    fontSize: 13, color: Colors.black54)),
                            const SizedBox(height: 4),
                            Text("₹${widget.ticket.price}",
                                style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE9D5FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TicketAIChatScreen(
                                        ticketInfo: {
                                          "title": widget.ticket.title,
                                          "category": widget.ticket.category,
                                          "date": widget.ticket.date,
                                          "time": widget.ticket.time,
                                          "venue": widget.ticket.venue,
                                          "seat": widget.ticket.seat,
                                          "price": widget.ticket.price,
                                          "description": widget.ticket.description,
                                        },
                                        ticketId: widget.ticket.title + widget.ticket.seller,
                                        userEmail: widget.buyerEmail,

                                      )
                                    ),
                                  );
                                },
                            child: Text("chat Ai Assistant",
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: primaryColor,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: widget.ticket.status == 'sold'
                        ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "SOLD OUT",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : ElevatedButton(
                            onPressed: _showPaymentOptions,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              "Buy Now",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              
                            ),
                          ),
                  )

                  ],
                ),
              ),
            ),

            // ---------- Description Section ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Description",
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black)),
                    const SizedBox(height: 8),
                    Text(
                      """
                        Event: ${widget.ticket.title}
                        Category: ${widget.ticket.category}
                        Date: ${widget.ticket.date} • Time: ${widget.ticket.time}
                        Venue: ${widget.ticket.venue}
                        Seat: ${widget.ticket.seat}
                        Price: ₹${widget.ticket.price}

                        Additional Info:
                        ${widget.ticket.description.isNotEmpty ? widget.ticket.description : "No extra description available."}
                        """,
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: Colors.black87, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: primaryColor, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.black,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
