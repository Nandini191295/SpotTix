

import 'dart:developer';

import 'package:dummy_firebase/view/login_screen.dart';
import 'package:dummy_firebase/view/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


void main()async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyCChKjJhfTM5xdYaOLNXeKT5t7BiFxUqd4", 
      
      appId: "1:236742280437:android:b495c9712f16bca04931bc",
       messagingSenderId: "236742280437",
        projectId: "ticket-5ea27",
        )
  );
  log("Firebase initialized");
  
  runApp(const MainApp());

}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
     debugShowCheckedModeBanner: false,
     navigatorKey:navigatorKey,
      home: const splashScreen()
    );
  }
}

 