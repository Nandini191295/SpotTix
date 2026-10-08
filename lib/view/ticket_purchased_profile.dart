import 'package:dummy_firebase/model/ticket_model_class.dart';
import 'package:flutter/material.dart';
import '../controller/ticket_controller.dart';

class PurchasedTicketsScreen extends StatefulWidget {
  const PurchasedTicketsScreen({super.key});

  @override
  State<PurchasedTicketsScreen> createState() => _PurchasedTicketsScreenState();
}

class _PurchasedTicketsScreenState extends State<PurchasedTicketsScreen> {
  final TicketController _controller = TicketController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Purchased Tickets"),
        centerTitle: true,
      ),
      body: StreamBuilder<List<TicketModel>>(
        stream: _controller.streamPurchasedTickets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No purchased tickets found."));
          }

          final tickets = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Image.asset("asset/logo.png"),
                  title: Text(ticket.title.isNotEmpty ? ticket.title : ticket.category,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    "Category: ${ticket.category}\nDate & Time: ${ticket.date} ${ticket.time}",
                  ),
                  trailing: Text("₹${ticket.price}",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}