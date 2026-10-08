import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class KycUploadScreen extends StatefulWidget {
  const KycUploadScreen({super.key});

  @override
  State<KycUploadScreen> createState() => _KycUploadScreenState();
}

class _KycUploadScreenState extends State<KycUploadScreen> {
  File? _kycFile;
  bool _isUploading = false;
  String? _fileName;

  // 🔹 Pick image or PDF file using file_selector
  Future<void> _pickFile() async {
    try {
      final typeGroup = XTypeGroup(
        label: 'documents',
        extensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      final file = await openFile(acceptedTypeGroups: [typeGroup]);

      if (file != null) {
        setState(() {
          _kycFile = File(file.path);
          _fileName = file.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking file: $e")),
      );
    }
  }

  // 🔹 Upload KYC file to Firebase Storage + update Firestore
  Future<void> _uploadKyc() async {
    if (_kycFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a KYC document first.")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final fileExtension = _kycFile!.path.split('.').last;
      final fileName = "kyc_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension";

      final storageRef = FirebaseStorage.instance.ref().child("kyc_docs/$fileName");
      await storageRef.putFile(_kycFile!);
      final fileUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user.email).set({
        'kycUrl': fileUrl,
        'isKycVerified': true,
        'kycUploadedAt': DateTime.now(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("KYC document uploaded successfully!")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading KYC: $e")),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("KYC Verification"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text(
              "Upload your KYC document (Aadhaar, PAN, or ID) to continue selling tickets.",
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // 🔹 Preview area
            _kycFile != null
                ? Column(
                    children: [
                      if (_kycFile!.path.endsWith('.pdf'))
                        const Icon(Icons.picture_as_pdf, size: 100, color: Colors.red)
                      else
                        Image.file(_kycFile!, height: 200, fit: BoxFit.cover),
                      const SizedBox(height: 10),
                      Text(
                        _fileName ?? 'Selected File',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  )
                : Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Text("No file selected"),
                  ),

            const SizedBox(height: 20),

            // 🔹 Select file button
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickFile,
              icon: const Icon(Icons.upload_file),
              label: const Text("Select File"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 30),

            // 🔹 Upload button
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadKyc,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Submit KYC"),
            ),
          ],
        ),
      ),
    );
  }
}