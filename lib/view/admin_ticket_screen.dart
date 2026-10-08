import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminTicketsScreen extends StatelessWidget {
  const AdminTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pending Tickets"),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Container(
        color: const Color(0xFFF9F7FF),
        padding: const EdgeInsets.all(24),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("tickets_pending")
              .orderBy("uploadedAt", descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No pending tickets."));
            }

            final tickets = snapshot.data!.docs;

            return ListView(
              children: tickets
                  .map((doc) => buildTicketCard(
                        context,
                        doc.id,
                        doc.data() as Map<String, dynamic>,
                      ))
                  .toList(),
            );
          },
        ),
      ),
    );
  }

  Widget buildTicketCard(
      BuildContext context, String docId, Map<String, dynamic> ticket) {
    // Determine category image
    String imagePath;
    switch ((ticket["category"] ?? "").toString().toLowerCase()) {
      case "concert":
        imagePath = "asset/concert.jpg";
        break;
      case "bus":
        imagePath = "asset/traveles.jpeg";
        break;
      case "movie":
        imagePath = "asset/movie ticket.jpeg";
        break;
      case "train":
        imagePath = "asset/train.jpeg";
        break;
      default:
        imagePath = "asset/default.jpeg"; // fallback
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12.withOpacity(0.1), blurRadius: 6)
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: Image.asset(
              imagePath,
              width: 180,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(
                        label: Text(ticket["status"] ?? "Pending"),
                        backgroundColor: ticket["status"] == "Pending"
                            ? const Color(0xFFFFF2C6)
                            : ticket["status"] == "Approved"
                                ? Colors.green[200]
                                : Colors.red[200],
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "ID: ${ticket["id"]}",
                        style: GoogleFonts.poppins(
                            color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text("Ticket Details",
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  _buildDataRow(Icons.event, "Event", ticket["event"]),
                  _buildDataRow(Icons.location_on, "Venue", ticket["venue"]),
                  _buildDataRow(Icons.schedule, "Date & Time", ticket["datetime"]),
                  _buildDataRow(Icons.event_seat, "Seat", ticket["seat"]),
                  _buildDataRow(
                      Icons.currency_rupee, "Price", ticket["price"] ?? "N/A"),
                  _buildDataRow(
                      Icons.category, "Category", ticket["category"] ?? "N/A"),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          _updateTicketStatus(
                            context,
                            docId,
                            "Approved",
                            ticket,
                          );
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text("Approve Ticket",
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromRGBO(138, 0, 255, 1)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          _updateTicketStatus(context, docId, "Rejected", ticket);
                        },
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text("Reject Ticket",
                            style: TextStyle(color: Colors.white)),
                        style:
                            ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      ),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _updateTicketStatus(BuildContext context, String ticketId,
      String status, Map<String, dynamic> ticketData) async {
    try {
      // 1️⃣ Update status in pending
      await FirebaseFirestore.instance
          .collection("tickets_pending")
          .doc(ticketId)
          .update({"status": status});

      // 2️⃣ If approved, move to available and update admin income
      if (status == "Approved") {
        Map<String, dynamic> dataToSave = {
          ...ticketData,
          "uploadedAt": FieldValue.serverTimestamp(),
          "status": "Approved",
        };

        await FirebaseFirestore.instance
            .collection("tickets_available")
            .doc(ticketId)
            .set(dataToSave);

        // Remove from pending
        await FirebaseFirestore.instance
            .collection("tickets_pending")
            .doc(ticketId)
            .delete();

        // ✅ Update Admin Income
        double price = double.tryParse(ticketData["price"].toString()) ?? 0.0;
        final adminDocs =
            await FirebaseFirestore.instance.collection("admin").get();
        if (adminDocs.docs.isNotEmpty) {
          var adminRef =
              FirebaseFirestore.instance.collection("admin").doc(adminDocs.docs.first.id);
          await adminRef.update({
            "income": FieldValue.increment(price),
          });
        }
      }

      // 3️⃣ Send notification
 
    // 3️⃣ Send formatted notification to user's subcollection
    final userEmail = ticketData["uploaderEmail"];
    if (userEmail != null && userEmail.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(userEmail)
          .collection("notifications")
          .add({
        "color": status == "Approved" ? "green" : "red",
        "icon": "ticket",
        "message": status == "Approved"
            ? "Your ticket '${ticketData["event"] ?? "Event"}' has been approved and is now live."
            : "Your ticket '${ticketData["event"] ?? "Event"}' has been rejected by admin.",
        "time": DateTime.now().toString(),
        "title": "Ticket ${status == "Approved" ? "Approved ✅" : "Rejected ❌"}",
        "userId": userEmail,
      });
    }



      // ✅ Show Snackbar Feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Ticket $status successfully!"),
          backgroundColor: status == "Approved" ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating ticket: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDataRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.purple),
          const SizedBox(width: 6),
          Text("$label: ",
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, fontSize: 13)),
          Expanded(
              child: Text(value ?? "N/A",
                  style: GoogleFonts.poppins(color: Colors.black87))),
        ],
      ),
    );
  }
}
