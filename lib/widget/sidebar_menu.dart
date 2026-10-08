import 'package:dummy_firebase/view/admin_ticket_screen.dart';
import 'package:dummy_firebase/view/admin_user_screen.dart';
import 'package:dummy_firebase/view/admin_wallet.dart';
// 👈 Added import
import 'package:dummy_firebase/view/login_screen.dart';
import 'package:flutter/material.dart';

class SidebarMenu extends StatefulWidget {
  const SidebarMenu({super.key});

  @override
  State<SidebarMenu> createState() => _SidebarMenuState();
}

class _SidebarMenuState extends State<SidebarMenu> {
  int selectedIndex = 0;

  final List<Widget> pages = [
    AdminUserScreen(),
    AdminTicketsScreen(),
    AdminWalletScreen() // 👈 Added wallet page
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 200,
            color: const Color(0xFFf7f4ff),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DrawerHeader(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Image.asset("asset/mm.jpg", height: 35, width: 35),
                          const Text(
                            " Admin",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color.fromRGBO(138, 0, 255, 1),
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        "Control Panel",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),

                // Menu Items
                buildNavItem(Icons.people, "Users", 0),
                buildNavItem(Icons.confirmation_number, "Tickets", 1),
                buildNavItem(Icons.account_balance_wallet, "Wallet", 2), // 👈 New

                const Spacer(),

                // Logout Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (context) {
                          return const LoginPage();
                        },
                      ));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      color: Colors.transparent,
                      child: const Row(
                        children: [
                          Icon(Icons.logout,
                              color: Colors.redAccent, size: 20),
                          SizedBox(width: 10),
                          Text(
                            "Logout",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Content Area
          Expanded(child: pages[selectedIndex]),
        ],
      ),
    );
  }

  Widget buildNavItem(IconData icon, String title, int index) {
    bool isSelected = selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        color:
            isSelected ? const Color.fromRGBO(138, 0, 255, 1) : Colors.transparent,
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color.fromRGBO(255, 255, 255, 1)
                  : Colors.black54,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? const Color.fromARGB(255, 255, 255, 255)
                    : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
