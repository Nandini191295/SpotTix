import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:dummy_firebase/widget/app_color.dart';
import 'package:dummy_firebase/controller/notification_service.dart';

class ScanResultScreen extends StatefulWidget {
  final File? ticketImage;

  const ScanResultScreen({super.key, this.ticketImage});

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  late TextEditingController eventController;
  late TextEditingController dateController;
  late TextEditingController venueController;
  late TextEditingController seatController;
  late TextEditingController priceController;

  late String originalEvent;
  late String originalDate;
  late String originalVenue;
  late String originalSeat;


  double aiConfidence = 0.0;
  bool isProcessing = true;
  bool _isUploading = false; // prevent duplicate uploads

  // Ticket categories
  final List<String> ticketCategories = ["Concert", "Train", "Bus", "Movie"];
  String selectedCategory = "Concert";

  @override
  void initState() {
    super.initState();
    eventController = TextEditingController(text: "N/A");
    dateController = TextEditingController(text: "N/A");
    venueController = TextEditingController(text: "N/A");
    seatController = TextEditingController(text: "N/A");
    priceController = TextEditingController();

    if (widget.ticketImage != null) {
      _extractTicketInfo(widget.ticketImage!);
    } else {
      isProcessing = false;
    }
  }

  @override
  void dispose() {
    eventController.dispose();
    dateController.dispose();
    venueController.dispose();
    seatController.dispose();
    priceController.dispose();
    super.dispose();
  }

  Future<void> _extractTicketInfo(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      List<String> lines = [];
      for (var block in recognizedText.blocks) {
        for (var line in block.lines) {
          lines.add(line.text.trim());
        }
      }

      String tempEvent = "N/A";
      String tempDate = "N/A";
      String tempVenue = "N/A";
      String tempSeat = "N/A";

      // Detect Date & Time
      for (var l in lines) {
        final dateMatch = RegExp(
          r'\b(\d{1,2}[-/]\d{1,2}[-/]\d{2,4}|\d{1,2}\s[a-zA-Z]{3,9}\s\d{2,4})\b',
        ).firstMatch(l);
        final timeMatch = RegExp(r'\b(\d{1,2}:\d{2})\b').firstMatch(l);
        if (dateMatch != null) {
          tempDate = timeMatch != null
              ? "${dateMatch.group(0)} ${timeMatch.group(0)}"
              : dateMatch.group(0)!;
          break;
        }
      }

      // Detect Seat
      for (var l in lines) {
        final seatMatch = RegExp(
          r'\b(seat|coach)\s*[:\-]?\s*[A-Z0-9]+\b',
          caseSensitive: false,
        ).firstMatch(l);
        if (seatMatch != null) {
          tempSeat = seatMatch.group(0)!;
          break;
        }
      }

      // Detect Event Name
      for (var l in lines) {
        if (!l.toLowerCase().contains("seat") &&
            !l.toLowerCase().contains("coach") &&
            !RegExp(r'\d{1,2}[-/]\d{1,2}[-/]\d{2,4}').hasMatch(l)) {
          tempEvent = l;
          break;
        }
      }

      // Detect Venue
      int dateIndex = lines.indexWhere((l) => l.contains(tempDate.split(' ')[0]));
      if (dateIndex >= 0 && dateIndex + 1 < lines.length) {
        tempVenue = lines[dateIndex + 1];
      }

      // Calculate confidence
      int detectedFields = 0;
      if (tempEvent != "N/A") detectedFields++;
      if (tempDate != "N/A") detectedFields++;
      if (tempVenue != "N/A") detectedFields++;
      if (tempSeat != "N/A") detectedFields++;
      aiConfidence = detectedFields / 4.0;

      eventController.text = tempEvent;
      dateController.text = tempDate;
      venueController.text = tempVenue;
      seatController.text = tempSeat;

      // ✅ Save originals for later comparison
      originalEvent = tempEvent;
      originalDate = tempDate;
      originalVenue = tempVenue;
      originalSeat = tempSeat;

      setState(() {
        isProcessing = false;
      });
    } catch (e) {
      debugPrint("Error extracting text: $e");
      setState(() => isProcessing = false);
    } finally {
      textRecognizer.close();
    }
  }

  Future<void> _onConfirm() async {
    if (_isUploading) return;
    setState(() => _isUploading = true);

    String ticketId = "TKT${DateTime.now().millisecondsSinceEpoch}";
    String sellerEmail = FirebaseAuth.instance.currentUser?.email ?? "Unknown";

    // Recalculate AI confidence before upload
    // aiConfidence = [
    //   eventController.text,
    //   dateController.text,
    //   venueController.text,
    //   seatController.text
    // ].where((text) => text != "N/A" && text.trim().isNotEmpty).length / 4.0;

    debugPrint("AI Confidence at confirm: $aiConfidence");


     if (aiConfidence < 0.75) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("⚠ Ticket rejected — AI score must be at least 75%"),
        backgroundColor: Colors.red,
      ),
    );
    setState(() => _isUploading = false);
    return;
  }
   try {
    // Try to parse the date (you can refine regex-based extraction later)
    DateTime? ticketDate;

    // Try multiple formats
    final rawDate = dateController.text.trim();
    if (RegExp(r'\d{1,2}[-/]\d{1,2}[-/]\d{2,4}').hasMatch(rawDate)) {
      final parts = rawDate.split(RegExp(r'[-/]'));
      if (parts.length >= 3) {
        int day = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        int year = int.parse(parts[2].length == 2 ? '20${parts[2]}' : parts[2]);
        ticketDate = DateTime(year, month, day);
      }
    }
        // If parsed and is in the past → reject
    if (ticketDate != null && ticketDate.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠ Ticket rejected — event date has expired"),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isUploading = false);
      return;
    }
  } catch (e) {
    debugPrint("⚠ Date parsing error: $e");
  }
  // ✅ Passed all checks — proceed with upload
    String imageUrl = "";
    if (widget.ticketImage != null) {
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child("tickets/${DateTime.now().millisecondsSinceEpoch}.jpg");
        await storageRef.putFile(widget.ticketImage!);
        imageUrl = await storageRef.getDownloadURL();
      } catch (e) {
        debugPrint("Image upload failed: $e");
      }
    }

    Map<String, dynamic> ticketData = {
      "id": ticketId,
      "event": eventController.text,
      "venue": venueController.text,
      "datetime": dateController.text,
      "seat": seatController.text,
      "price": priceController.text.isEmpty ? "N/A" : priceController.text,
      "category": selectedCategory,
      "image": imageUrl,
      "uploader": sellerEmail,
      "status": "Pending",
      "aiConfidence": aiConfidence,
      "uploadedAt": FieldValue.serverTimestamp(),
    
    };

    try {
      final firestore = FirebaseFirestore.instance;

      await firestore.collection("tickets_pending").doc(ticketId).set(ticketData);

      await firestore
          .collection("users")
          .doc(sellerEmail)
          .collection("uploaded_tickets")
          .doc(ticketId)
          .set(ticketData);

      // Optional: Trigger notification
      final notif = NotificationService();
      await notif.sendNotification(
        title: "Ticket Upload Submitted",
        message: "Your ticket '${eventController.text}' is pending review.",
        icon: "ticket",
        color: "purple",
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ticket sent to admin for review!!!!!"),
          backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint("Error uploading ticket: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to send ticket"),
        backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _onCancel() => Navigator.pop(context);

 Widget _buildField(String label, TextEditingController controller, {String? originalValue}) {
  bool isNA = controller.text == "N/A";

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: Colors.black54,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        onChanged: (value) {
          // 🔹 Drop confidence if seller edits any AI-extracted field
          if (originalValue != null && value.trim() != originalValue.trim()) {
            setState(() {
              aiConfidence = 0.5; // Drop below threshold
            });
          }
        },
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isNA ? Colors.red : Colors.grey,
              width: isNA ? 2 : 1.5,
            ),
          ),
          hintText: isNA ? "Enter $label" : null,
        ),
      ),
    ],
  );
}




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isProcessing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Center(
                child: Container(
                  width: 350,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        decoration: const BoxDecoration(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(25)),
                          color: AppColors.purple,
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 25, horizontal: 16),
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle_outline,
                                color: Colors.white, size: 45),
                            const SizedBox(height: 10),
                            Text(
                              "Scan Successful!",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Please verify and edit the ticket details if needed",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Ticket Image
                      if (widget.ticketImage != null)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              widget.ticketImage!,
                              height: 200,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildField("Event/Train Name", eventController, originalValue: originalEvent),
                            const SizedBox(height: 15),
                            _buildField("Date & Time", dateController, originalValue: originalDate),
                            const SizedBox(height: 15),
                            _buildField("Venue / From-To", venueController, originalValue: originalVenue),
                            const SizedBox(height: 15),
                           _buildField("Seat / Coach", seatController, originalValue: originalSeat),
                            const SizedBox(height: 15),
                            _buildField("Price (₹)", priceController),
                            const SizedBox(height: 15),

                            // Category Dropdown
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Ticket Category",
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  value: selectedCategory,
                                  items: ticketCategories
                                      .map((category) => DropdownMenuItem(
                                            value: category,
                                            child: Text(category),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedCategory = value!;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 12),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  onPressed: _isUploading ? null : _onConfirm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.purple,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 30, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isUploading
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          "Confirm",
                                          style: TextStyle(
                                              color: Colors.white),
                                        ),
                                ),
                                OutlinedButton(
                                  onPressed: _onCancel,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 30, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    side: const BorderSide(
                                        color: Colors.grey, width: 1.5),
                                  ),
                                  child: const Text("Cancel"),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            LinearProgressIndicator(
                              value: aiConfidence,
                              color: AppColors.purple,
                              backgroundColor: Colors.grey[300],
                            ),
                            Text(
                              "AI Confidence: ${(aiConfidence * 100).toStringAsFixed(0)}%",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: aiConfidence >= 0.75 ? Colors.green : Colors.orange,
                              ),
                            ),

                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}