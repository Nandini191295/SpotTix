import "dart:developer";

import "package:dummy_firebase/view/chat_screen.dart";
import "package:dummy_firebase/view/home_screen.dart";
import "package:dummy_firebase/view/profile_screen.dart";
import "package:dummy_firebase/view/sell_screen.dart";
import "package:dummy_firebase/view/wallet_screen.dart";
import"package:flutter/material.dart";
class bottomNavigationScreen extends StatefulWidget {
  const bottomNavigationScreen({super.key});

  @override
  State<bottomNavigationScreen> createState() =>_bottomNavigationScreenState();
}

class _bottomNavigationScreenState extends State<bottomNavigationScreen> {
  TextEditingController searchBarController=TextEditingController();
  int currentSelectIndex=0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
         backgroundColor: Color.fromRGBO(241, 245, 250, 1),
      body:Pages(currentSelectIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentSelectIndex,
        selectedItemColor: Color.fromRGBO(138, 0, 255, 1),
        unselectedItemColor: Color.fromRGBO(126, 121, 121, 0.997),
        onTap: (value){
          log("Index: $value");
          currentSelectIndex=value;
          setState(() {
            
          });
        },
        items:[
          BottomNavigationBarItem(icon: Icon(Icons.home),label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.chat),label: "Message"),
          BottomNavigationBarItem(icon: Icon(Icons.add),label: "Sell"),
          BottomNavigationBarItem(icon: Icon(Icons.wallet),label: "Wallet"),
          BottomNavigationBarItem(icon: Icon(Icons.person),label: "Profile"),

        ]),

    );
  }
  Pages(int index){
    switch(index){
      case 0:
      return HomeScreen();
      case 1:
      return ChatScreen();
      case 2: 
      return sellScreen();
      case 3:
      return WalletScreen();
      case 4:
      return ProfileScreen();

    }
  }
}