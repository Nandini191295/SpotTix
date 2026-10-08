import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TicketAIChatScreen extends StatefulWidget {
  final Map<String, dynamic> ticketInfo;
  final String ticketId;
  final String userEmail;

  const TicketAIChatScreen({
    super.key,
    required this.ticketInfo,
    required this.ticketId,
    required this.userEmail,
  });

  @override
  State<TicketAIChatScreen> createState() => _TicketAIChatScreenState();
}

class _TicketAIChatScreenState extends State<TicketAIChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  double walletBalance = 0.0;
  String userName = "Sir/Madam";

  @override
  void initState() {
    super.initState();
    _loadUserNameAndWallet();
  }

 Future<void> _loadUserNameAndWallet() async {
  final doc = await _firestore.collection('users').doc(widget.userEmail).get();
  if (doc.exists) {
    setState(() {
      userName = doc.data()?['name'] ?? ""; // Take full name directly
      walletBalance = (doc.data()?['walletBalance'] ?? 0).toDouble();
    });
  }
}

  Future<void> _scrollToBottom() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final ticketDocRef = _firestore
        .collection('users')
        .doc(widget.userEmail)
        .collection('ticket_ai_chats')
        .doc(widget.ticketId);

    // Ensure parent document exists
    await ticketDocRef.set({
      'ticketTitle': widget.ticketInfo['title'],
      'price': widget.ticketInfo['price'] ?? '0',
      'lastMessage': text,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final messageRef = ticketDocRef.collection('messages');

    await messageRef.add({
      'sender': 'user',
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _controller.clear();

    String aiResponse = await _generateAIResponse(text, widget.ticketInfo);

    await messageRef.add({
      'sender': 'AI',
      'text': aiResponse,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update lastMessage for chat listing
    await ticketDocRef.update({
      'lastMessage': aiResponse,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    _scrollToBottom();
  }

  Future<String> _generateAIResponse(String question, Map<String, dynamic> ticket) async {
    question = question.toLowerCase();
    const appName = "SpotTix";

    if (question.contains("payment") || question.contains("buy") || question.contains("pay")) {
      return "Hello $userName 👋,\nYou can pay for '${ticket['title']}' using Wallet or UPI. Please choose your preferred method.";
    }

    if (question.contains("available") || question.contains("sold out") || question.contains("can i buy")) {
      if (ticket['isAvailable'] == true) {
        return "Hello $userName 👋,\nThe ticket '${ticket['title']}' is currently available. You can proceed with booking at your convenience. Thank you for using $appName!";
      } else {
        return "Hello $userName 👋,\nUnfortunately, the ticket '${ticket['title']}' has already been sold out. Thank you for using $appName!";
      }
    }

    if (question.contains("seat") || question.contains("vip")) {
      return "Greetings $userName,\nYour seat for '${ticket['title']}' is ${ticket['seat']} at ${ticket['venue']}. Thank you for using $appName.";
    }

    if (question.contains("price") || question.contains("cost")) {
      return "Hello $userName,\nThe ticket '${ticket['title']}' is priced at ₹${ticket['price']}. Thank you for choosing $appName!";
    }

    if (question.contains("date") || question.contains("time") || question.contains("when")) {
      return "Hello $userName,\nThe event '${ticket['title']}' is scheduled for ${ticket['date']} at ${ticket['time']}. Thank you for using $appName!";
    }

    if (question.contains("venue") || question.contains("where")) {
      return "Hello $userName,\nThe '${ticket['title']}' event will be held at ${ticket['venue']}. Thank you for using $appName!";
    }

    if (question.contains("info") || question.contains("description") || question.contains("details")) {
      return "Hello $userName,\nHere is a brief overview of '${ticket['title']}': ${ticket['description']}. Thank you for using $appName!";
    }

    return "Hello $userName 👋,\nI am your AI assistant in $appName for the ticket '${ticket['title']}'. You can ask about availability, price, seat, date/time, venue, event details, or payment options. Thank you for using $appName!";
  }

  Future<void> handleWalletPayment(double amount) async {
    if (walletBalance < amount) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Insufficient wallet balance, $userName.")));
      return;
    }

    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Wallet Payment"),
        content: Text("₹$amount will be deducted from your wallet. Proceed?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("OK")),
        ],
      ),
    );

    if (confirm != true) return;

    walletBalance -= amount;

    final userDocRef = _firestore.collection('users').doc(widget.userEmail);
    await userDocRef.update({
      'walletBalance': walletBalance,
      'walletHistory': FieldValue.arrayUnion([
        {
          'ticket': widget.ticketInfo['title'],
          'amount': amount,
          'method': 'Wallet',
          'timestamp': FieldValue.serverTimestamp(),
        }
      ]),
    });

    await _sendPaymentReceipt("Wallet", amount);
  }

  Future<void> handleUPIPayment(double amount) async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("UPI Payment"),
        content: Text("You will pay ₹$amount via UPI. Proceed?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("OK")),
        ],
      ),
    );

    if (confirm != true) return;

    await _sendPaymentReceipt("UPI", amount);
  }

  Future<void> _sendPaymentReceipt(String method, double amount) async {
    final ticketDocRef = _firestore
        .collection('users')
        .doc(widget.userEmail)
        .collection('ticket_ai_chats')
        .doc(widget.ticketId);

    final messageRef = ticketDocRef.collection('messages');

    // Congratulatory message
    await messageRef.add({
      'sender': 'AI',
      'text': "🎉 Congratulations $userName! Your payment of ₹$amount via $method for '${widget.ticketInfo['title']}' is successful. Thank you for using SpotTix!",
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Receipt message
    await messageRef.add({
      'sender': 'AI',
      'text': 'RECEIPT_CARD',
      'timestamp': FieldValue.serverTimestamp(),
      'receipt': {
        'ticket': widget.ticketInfo['title'],
        'amount': amount,
        'method': method,
        'date': widget.ticketInfo['date'],
        'time': widget.ticketInfo['time'],
        'venue': widget.ticketInfo['venue'],
      }
    });

    // Update lastMessage for ChatScreen
    await ticketDocRef.update({
      'lastMessage': "Payment successful via $method",
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    await _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(widget.ticketInfo['price'].toString()) ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("SpotTix AI Assistant"),
        backgroundColor: const Color.fromRGBO(138, 0, 255, 1),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(widget.userEmail)
                  .collection('ticket_ai_chats')
                  .doc(widget.ticketId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final messages = snapshot.data!.docs;
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final isAI = data['sender'] == 'AI';

                    // Receipt Card
                    if (isAI && data['text'] == 'RECEIPT_CARD' && data.containsKey('receipt')) {
                      final receipt = data['receipt'] as Map<String, dynamic>;
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(right:10.0,left:15),
                          child: Container(
                            margin: const EdgeInsets.all(15),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 209, 205, 88),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("🎫 SpotTix Receipt",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 6),
                                  Text("Ticket: ${receipt['ticket']}"),
                                  Text("Amount: ₹${receipt['amount']}"),
                                  Text("Payment Method: ${receipt['method']}"),
                                  Text("Date: ${receipt['date']}  Time: ${receipt['time']}"),
                                  Text("Venue: ${receipt['venue']}"),
                                  const SizedBox(height: 6),
                                  const Text("Thank you for using SpotTix!",
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    return Align(
                      alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right:3.0,left:5),
                        child: Container(
                          margin: const EdgeInsets.all(15),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isAI
                                ? const Color.fromARGB(255, 148, 131, 175)
                                : const Color.fromRGBO(138, 0, 255, 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            data['text'] ?? '',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left:10.0),
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Ask about the ticket...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Color.fromRGBO(138, 0, 255, 1)),
                onPressed: _sendMessage,
              ),
              IconButton(
                icon: const Icon(Icons.account_balance_wallet, color: Colors.green),
                onPressed: () => handleWalletPayment(amount),
              ),
              IconButton(
                icon: const Icon(Icons.payment, color: Colors.orangeAccent),
                onPressed: () => handleUPIPayment(amount),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
