import 'dart:io';
import 'package:camera/camera.dart';
import 'package:dummy_firebase/view/scan_sucessful_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart'; // added

class sellScreen extends StatefulWidget {
  const sellScreen({super.key});

  @override
  State<sellScreen> createState() => _sellScreenState();
}

class _sellScreenState extends State<sellScreen>
    with SingleTickerProviderStateMixin {
  static const Color _darkPurple = Color.fromARGB(255, 30, 14, 55);
  static const Color _vibrantPurple = Color.fromARGB(255, 128, 0, 255);

  late AnimationController _controller;
  late Animation<double> _animation;

  CameraController? _cameraController;
  List<CameraDescription>? cameras;
  XFile? _capturedTicket;

  final ImagePicker _picker = ImagePicker();
  File? _ticketImage;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 60, end: 340).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    if (cameras!.isNotEmpty) {
      _cameraController =
          CameraController(cameras![0], ResolutionPreset.high);
      await _cameraController!.initialize();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _scanWithCamera() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        _capturedTicket = await _cameraController!.takePicture();
        if (_capturedTicket != null) {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) =>
                  ScanResultScreen(ticketImage: File(_capturedTicket!.path))));
        }
      } catch (e) {
        print("Error capturing image: $e");
      }
    }
  }

  Future<void> _pickTicketFromGallery() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _ticketImage = File(pickedFile.path);
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ScanResultScreen(ticketImage: _ticketImage!)));
    }
  }

  Widget _buildInstructionItem(int number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color.fromRGBO(138, 0, 255, 1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "AI Ticket Scanner",
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 10),
              Container(
                height: 400,
                decoration: BoxDecoration(
                  color: _darkPurple,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _cameraController != null &&
                        _cameraController!.value.isInitialized
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          CameraPreview(_cameraController!),
                          AnimatedBuilder(
                            animation: _animation,
                            builder: (context, child) {
                              return Positioned(
                                top: _animation.value,
                                child: Container(
                                  width: 250,
                                  height: 2.5,
                                  decoration: BoxDecoration(
                                    color: _vibrantPurple,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            _vibrantPurple.withOpacity(0.6),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const Text(
                            "Align ticket within frame",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      )
                    : const Center(
                        child: CircularProgressIndicator(),
                      ),
              ),
              const SizedBox(height: 30),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    _buildInstructionItem(1, "Place the ticket flat on a surface"),
                    _buildInstructionItem(2, "Align ticket within the frame"),
                    _buildInstructionItem(3, "Tap scan or upload when ready"),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _scanWithCamera,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _vibrantPurple,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                label: const Text(
                  "Scan Ticket",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: _pickTicketFromGallery,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
                icon: const Icon(Icons.upload_file, color: Colors.white),
                label: const Text(
                  "Upload Ticket",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
