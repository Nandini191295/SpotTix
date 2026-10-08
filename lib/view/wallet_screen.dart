import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dummy_firebase/view/wallet_sqflite.dart';
import 'package:dummy_firebase/widget/app_color.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  double walletBalance = 0.0;
  double totalEarned = 0.0;
  double totalSpent = 0.0;
  List<Map<String, dynamic>> transactions = [];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String uid;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(
            begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();

    uid = _auth.currentUser?.uid ?? "";
    _loadLocalWallet();
    _listenWalletUpdates();
    _listenAdminReleaseUpdates(); // ✅ Added listener for admin release
  }

  // Load local SQLite wallet first
  Future<void> _loadLocalWallet() async {
    final localWallet = await WalletDBHelper.getWallet(uid);
    final localTx = await WalletDBHelper.getTransactions(uid);
    if (localWallet != null) {
      setState(() {
        walletBalance = (localWallet['balance'] ?? 0).toDouble();
        totalEarned = (localWallet['totalEarned'] ?? 0).toDouble();
        totalSpent = (localWallet['totalSpent'] ?? 0).toDouble();
        transactions = List<Map<String, dynamic>>.from(localTx);
      });
    }
  }

  // Listen Firestore changes in real-time
  void _listenWalletUpdates() {
    _firestore.collection('users').doc(uid).snapshots().listen((doc) async {
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          walletBalance = (data['walletBalance'] ?? 0).toDouble();
          totalEarned = (data['totalEarned'] ?? 0).toDouble();
          totalSpent = (data['totalSpent'] ?? 0).toDouble();
          transactions =
              List<Map<String, dynamic>>.from(data['transactions'] ?? []);
        });

        // Save to SQLite for offline caching
        await WalletDBHelper.insertWallet(uid, {
          'balance': walletBalance,
          'totalEarned': totalEarned,
          'totalSpent': totalSpent,
        });
        for (var tx in transactions) {
          await WalletDBHelper.insertTransaction(uid, tx);
        }
      }
    });
  }

  // ✅ Listen to AdminWallet releases (payment credited to seller)
  void _listenAdminReleaseUpdates() {
    _firestore
        .collection('AdminWallet')
        .where('sellerId', isEqualTo: uid)
        .where('status', isEqualTo: 'released')
        .snapshots()
        .listen((snapshot) async {
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final double releasedAmount = data['amount']?.toDouble() ?? 0.0;
        final double commission = releasedAmount * 0.02;
        final double sellerAmount = releasedAmount - commission;
        final ticketId = data['ticketId'] ?? "";

        // Check if transaction already exists to avoid duplicates
        bool alreadyExists = transactions.any((t) =>
            t['title'] ==
            'Payment Released by Admin for Ticket $ticketId');

        if (!alreadyExists) {
          final tx = {
            "title": "Payment Released by Admin for Ticket $ticketId",
            "amount": sellerAmount,
            "type": "credit",
            "date": DateTime.now().toString().split(" ")[0],
            "time": TimeOfDay.now().format(context),
            "status": "Completed",
          };

          await _firestore.collection('users').doc(uid).update({
            'walletBalance': FieldValue.increment(sellerAmount),
            'totalEarned': FieldValue.increment(sellerAmount),
            'transactions': FieldValue.arrayUnion([tx]),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '₹${sellerAmount.toStringAsFixed(2)} credited from Admin release'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    });
  }

  Future<void> _addMoney() async {
    double? amount = await _showAmountDialog("Add Money");
    if (amount != null && amount > 0) {
      final tx = {
        "title": "Wallet Top-Up",
        "amount": amount,
        "type": "credit",
        "date": DateTime.now().toString().split(" ")[0],
        "time": TimeOfDay.now().format(context),
        "status": "Completed",
      };

      await _firestore.collection('users').doc(uid).update({
        'walletBalance': FieldValue.increment(amount),
        'totalEarned': FieldValue.increment(amount),
        'transactions': FieldValue.arrayUnion([tx]),
      });
    }
  }

  Future<void> _withdrawMoney() async {
    double? amount = await _showAmountDialog("Withdraw Money");
    if (amount != null && amount > 0) {
      if (amount > walletBalance) {
        _showMessage("Insufficient balance");
        return;
      }

      final tx = {
        "title": "Wallet Withdrawal",
        "amount": amount,
        "type": "debit",
        "date": DateTime.now().toString().split(" ")[0],
        "time": TimeOfDay.now().format(context),
        "status": "Completed",
      };

      await _firestore.collection('users').doc(uid).update({
        'walletBalance': FieldValue.increment(-amount),
        'totalSpent': FieldValue.increment(amount),
        'transactions': FieldValue.arrayUnion([tx]),
      });
    }
  }

  Future<double?> _showAmountDialog(String title) async {
    final controller = TextEditingController();
    double? result;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "Enter amount"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              result = double.tryParse(controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
    return result;
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Wallet",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600))),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _walletBalanceCard(),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAnimatedInfoCard(
                        "Total Earned", totalEarned, Colors.green, 0),
                    const SizedBox(width: 15),
                    _buildAnimatedInfoCard(
                        "Total Spent", totalSpent, Colors.red, 1),
                  ],
                ),
                const SizedBox(height: 20),
                const Text("Transaction History",
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                _buildTransactionList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI helper methods ---
  Widget _walletBalanceCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.purple, AppColors.lightBackground],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.wallet_outlined,
                  size: 25, color: Color.fromRGBO(255, 255, 255, 1)),
              SizedBox(width: 10),
              Text("Wallet Balance",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color.fromRGBO(255, 255, 255, 1))),
              Spacer(),
              Icon(Icons.show_chart_sharp,
                  color: Color.fromRGBO(255, 255, 255, 1), size: 16),
            ],
          ),
          const SizedBox(height: 10),
          Text("₹${walletBalance.toStringAsFixed(2)}",
              style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const Text("Available to spend",
              style:
                  TextStyle(fontSize: 14, color: Color.fromRGBO(255, 255, 255, 1))),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(255, 255, 255, 1),
                    minimumSize: const Size(150, 40)),
                onPressed: _addMoney,
                icon: const Icon(Icons.add,
                    size: 15, color: Color.fromRGBO(0, 0, 0, 1)),
                label: const Text("Add Money",
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(0, 0, 0, 1))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(255, 255, 255, 1),
                    minimumSize: const Size(100, 40)),
                onPressed: _withdrawMoney,
                child: const Text("Withdraw",
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(0, 0, 0, 1))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedInfoCard(
      String title, double amount, Color color, int index) {
    return ScaleTransition(
      scale: CurvedAnimation(
          parent: _controller,
          curve:
              Interval(0.3 + index * 0.2, 1.0, curve: Curves.easeOutBack)),
      child: _buildInfoCard(title, amount, color),
    );
  }

  Widget _buildInfoCard(String title, double amount, Color color) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
          ]),
      child: Column(
        children: [
          Icon(Icons.arrow_downward, color: color, size: 25),
          const SizedBox(height: 10),
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB2B0B0))),
          Text(amount.toStringAsFixed(2),
              style:
                  TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        bool isCredit = tx["type"] == "credit";
        Color txColor = isCredit ? Colors.green : Colors.red;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
              ]),
          child: Row(
            children: [
              Icon(
                isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                color: txColor,
                size: 25,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: Text(tx["title"],
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600))),
                        Text(
                            isCredit
                                ? "+ ₹${tx["amount"]}"
                                : "- ₹${tx["amount"]}",
                            style: TextStyle(
                                color: txColor,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text("${tx["date"]} ${tx["time"]}"),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color:
                                  isCredit ? Colors.green[50] : Colors.red[50],
                              borderRadius: BorderRadius.circular(10)),
                          child: Text(tx["status"],
                              style: TextStyle(
                                  color: txColor,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
