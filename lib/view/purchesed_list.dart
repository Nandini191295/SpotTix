import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/ticket_model_class.dart';
import 'ticket_recipt_screen.dart';

class PurchasedTicketsListScreen extends StatelessWidget {
  final List<TicketModel> tickets;
  final String buyerEmail;

  const PurchasedTicketsListScreen({
    super.key,
    required this.tickets,
    required this.buyerEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Purchased Tickets"),
        backgroundColor: Colors.green,
      ),
      body: ListView.builder(
        itemCount: tickets.length,
        itemBuilder: (context, index) {
          final ticket = tickets[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: const Icon(Icons.confirmation_num,
                  color: Colors.green, size: 36),
              title: Text(ticket.title,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              subtitle: Text("${ticket.date} • ${ticket.venue}",
                  style: GoogleFonts.poppins(fontSize: 13)),
              trailing: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TicketReceiptScreen(
                        ticket: ticket,
                        buyerEmail: buyerEmail,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text("View Receipt",
                    style: GoogleFonts.poppins(color: Colors.white)),
              ),
            ),
          );
        },
      ),
    );
  }
}
