import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dummy_firebase/view/ticket_recipt_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/ticket_model_class.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final String message;
  final TicketModel ticket;

  const PaymentSuccessScreen({super.key, required this.message, required this.ticket});

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  final Random _random = Random();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String buyerName = "Guest";

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
    _fetchBuyerName();
  }

  Future<void> _fetchBuyerName() async {
    try {
      final userId = _auth.currentUser!.uid;
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        setState(() {
          buyerName = doc.data()?['name'] ?? "Guest";
        });
      }
    } catch (e) {
      print("Error fetching buyer name: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildSparkle() {
    final size = _random.nextDouble() * 6 + 4;
    final top = _random.nextDouble() * 120;
    final left = _random.nextDouble() * 120;
    final color = Colors.yellowAccent.withOpacity(_random.nextDouble() * 0.8 + 0.2);
    return Positioned(
      top: top,
      left: left,
      child: Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sparkles = List.generate(20, (_) => _buildSparkle());

    return Scaffold(
      backgroundColor: Colors.green.shade700,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Stack(alignment: Alignment.center, children: [
              ...sparkles,
              ScaleTransition(
                scale: _scaleAnimation,
                child: Icon(Icons.check_circle_outline, size: 120, color: Colors.white),
              ),
            ]),
            const SizedBox(height: 30),
            Text(widget.message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Navigate to Ticket Receipt screen with buyer name
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TicketReceiptScreen(
                      ticket: widget.ticket,
                      buyerEmail: _auth.currentUser!.email ?? "",
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                "View Receipt",
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600, color: Colors.green.shade700),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
