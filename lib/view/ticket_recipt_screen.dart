import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import '../model/ticket_model_class.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class TicketReceiptScreen extends StatelessWidget {
  final TicketModel ticket;
  final String buyerEmail; // current user's name

  const TicketReceiptScreen({
    super.key,
    required this.ticket,
    required this.buyerEmail,
  });

  // Keep the same PDF download function
  Future<void> _downloadTicket(BuildContext context) async {
  try {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6,
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              gradient: const pw.LinearGradient(
                colors: [PdfColors.purple300, PdfColors.purple900],
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
              ),
              borderRadius: pw.BorderRadius.circular(16),
            ),
            padding: const pw.EdgeInsets.all(16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // App Logo + Name
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                   // pw.Icon(pw.IconData(0xe001), color: PdfColors.white, size: 28), // Optional custom icon
                    pw.SizedBox(width: 8),
                    pw.Text(
                      "Spotix",
                      style: pw.TextStyle(
                        fontSize: 26,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),

                // Congrats Banner
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      " Congrats, $buyerEmail!",
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green900,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(height: 16),

                // Event Details Card
                pw.Container(
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  padding: const pw.EdgeInsets.all(16),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildPdfDetailRow("Event", ticket.title),
                      _buildPdfDetailRow("Category", ticket.category),
                      _buildPdfDetailRow("Date & Time", "${ticket.date} • ${ticket.time}"),
                      _buildPdfDetailRow("Venue", ticket.venue),
                      _buildPdfDetailRow("Seat", ticket.seat),
                      _buildPdfDetailRow("Price Paid", "${ticket.price}", isPrice: true),
                    ],
                  ),
                ),

                pw.Spacer(),

                // Footer
                pw.Center(
                  child: pw.Text(
                    "Thank you for booking with Spotix ",
                    style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.white,
                        fontStyle: pw.FontStyle.italic),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/ticket_${ticket.seat}.pdf');
    await file.writeAsBytes(bytes);

    await OpenFile.open(file.path);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Failed to download ticket.")),
    );
  }
}

// Helper for PDF ticket details
pw.Widget _buildPdfDetailRow(String label, String value, {bool isPrice = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 14, color: PdfColors.grey800)),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 14,
                fontWeight: isPrice ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: isPrice ? PdfColors.green : PdfColors.black)),
      ],
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        //backgroundColor: Color.fromRGBO(138, 0, 255, 1),
        title: const Text("Your Ticket"),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Logo + App Name
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.confirmation_num, color: Color.fromRGBO(138, 0, 255, 1), size: 32),
                const SizedBox(width: 8),
                Text(
                  "Spotix",
                  style: GoogleFonts.poppins(
                      fontSize: 28, fontWeight: FontWeight.bold, color: Color.fromRGBO(138, 0, 255, 1)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Congratulation Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Color.fromRGBO(138, 0, 255, 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color.fromRGBO(138, 0, 255, 001)),
              ),
              child: Text(
                "🎉 Congrats, $buyerEmail!",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w600, color: Color.fromRGBO(138, 0, 255, 1)),
              ),
            ),
            const SizedBox(height: 24),

            // Ticket Details Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 6,
              shadowColor: Color.fromRGBO(138, 0, 255,0.3),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow("Event", ticket.title),
                    _buildDetailRow("Category", ticket.category),
                    _buildDetailRow("Date & Time", "${ticket.date} • ${ticket.time}"),
                    _buildDetailRow("Venue", ticket.venue),
                    _buildDetailRow("Seat", ticket.seat),
                    _buildDetailRow("Price Paid", "₹${ticket.price}", isPrice: true),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Download Button
            ElevatedButton.icon(
              onPressed: () => _downloadTicket(context),
              icon: const Icon(Icons.download,color:Color.fromRGBO(0255, 255, 255, 1) ,),
              label: const Text("Download Ticket",style:TextStyle(color: Color.fromRGBO(0255, 255, 255, 1)) ,),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromRGBO(138, 0, 255, 1),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for ticket details
  Widget _buildDetailRow(String label, String value, {bool isPrice = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[800])),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: isPrice ? FontWeight.w600 : FontWeight.normal,
                  color: isPrice ? Colors.green : Colors.black)),
        ],
      ),
    );
  }
}
