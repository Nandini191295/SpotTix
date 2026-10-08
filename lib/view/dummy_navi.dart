import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

import 'package:dummy_firebase/view/home_screen.dart';
import 'package:dummy_firebase/view/chat_screen.dart';
import 'package:dummy_firebase/view/sell_screen.dart';
import 'package:dummy_firebase/view/wallet_screen.dart';
import 'package:dummy_firebase/view/profile_screen.dart';

class BottomNavigationScreen extends StatefulWidget {
  const BottomNavigationScreen({super.key});

  @override
  State<BottomNavigationScreen> createState() => _BottomNavigationScreenState();
}

class _BottomNavigationScreenState extends State<BottomNavigationScreen> {
  int currentIndex = 0;

  // 🔹 All pages in the order they appear in the nav bar
  final List<Widget> pages = const [
    HomeScreen(),
    ChatScreen(),
    sellScreen(),
    WalletScreen(),
    ProfileScreen(),
  ];

  // 🔹 Bottom nav icons
  final items = const <Widget>[
    Icon(Icons.home, size: 30, color: Colors.white),
    Icon(Icons.chat, size: 30, color: Colors.white),
    Icon(Icons.sell_outlined, size: 30, color: Colors.white),
    Icon(Icons.wallet, size: 30, color: Colors.white),
    Icon(Icons.person, size: 30, color: Colors.white),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(241, 245, 250, 1),
      body: pages[currentIndex],
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        color: const Color.fromARGB(137, 93, 31, 194),
        buttonBackgroundColor: const Color.fromARGB(255, 74, 23, 175),
        height: 60,
        items: items,
        index: currentIndex,
        animationDuration: const Duration(milliseconds: 300),
        onTap: (index) {
          setState(() => currentIndex = index);
        },
      ),
    );
  }
}
