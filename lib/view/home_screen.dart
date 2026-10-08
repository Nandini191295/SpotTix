import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dummy_firebase/model/ticket_model_class.dart';
import 'package:dummy_firebase/view/login_screen.dart';
import 'package:dummy_firebase/view/notification_screen.dart';
import 'package:dummy_firebase/view/ticket_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController searchBarController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? selectedCategory;

  late AnimationController _controller;
  late Animation<Offset> _headerSlide;
  late Animation<Offset> _searchSlide;
  late Animation<Offset> _categorySlide;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _searchSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _categorySlide =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    searchBarController.dispose();
    super.dispose();
  }

  // ----------------------------- Helper Methods -----------------------------

  Future<double> getWalletBalance() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return 0.0;

    final doc = await _firestore.collection('users').doc(userId).get();
    return (doc.data()?['walletBalance'] ?? 0).toDouble();
  }

  String getCategoryImage(String category) {
    switch (category.toLowerCase()) {
      case "concert":
        return "https://thumbs.dreamstime.com/b/rock-concert-large-group-happy-people-enjoying-clapping-raised-up-hands-blue-lights-stage-new-year-celebration-46521228.jpg";
      case "bus":
        return "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQQs9g-Sk2gpShYvEgEzHvSQWNHwaCG2uMNYQ&s";
      case "train":
        return "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSp4p-ppXYt7iuk35f1RnytqoGKsFEtMEM-VA&s";
      case "movie":
        return "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT9jWPkisGwN6uDvljD3qXtOAXRz5CDd6Z_LQ&s";
      default:
        return "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRA1fTC_E2ndOCqRChIt7zcfF9xtsn1X3n1tg&s";
    }
  }

  bool isTicketExpired(dynamic datetime) {
    if (datetime == null) return true;
    DateTime ticketDate;

    if (datetime is Timestamp) {
      ticketDate = datetime.toDate();
    } else if (datetime is String) {
      try {
        ticketDate = DateFormat('dd/MM/yyyy').parse(datetime);
      } catch (_) {
        return true;
      }
    } else {
      return true;
    }

    final today = DateTime.now();
    return DateTime(ticketDate.year, ticketDate.month, ticketDate.day)
        .isBefore(DateTime(today.year, today.month, today.day));
  }

  // ----------------------------- Build UI -----------------------------

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return WillPopScope(
      onWillPop: () async {
        setState(() => selectedCategory = null);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F6FB),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------------- Header ----------------
                SlideTransition(
                  position: _headerSlide,
                  child: FadeTransition(
                    opacity: _fadeIn,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("SpotTix",
                                style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87)),
                            Text("Find your perfect event",
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: const Color.fromRGBO(138, 0, 255, 1))),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => NotificationScreen(
                                userEmail: user?.email ?? "unknown",
                              ),
                            ),
                          ),
                          child: Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(138, 0, 255, 1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.notifications_none_outlined,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ---------------- Search Bar ----------------
                SlideTransition(
                  position: _searchSlide,
                  child: FadeTransition(
                    opacity: _fadeIn,
                    child: GestureDetector(
                   
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black12.withOpacity(0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 3))
                          ],
                        ),
                        child: TextField(
                          controller: searchBarController,
                          decoration: InputDecoration(
                            hintText: "Search events, venues...",
                            prefixIcon:
                                const Icon(Icons.search, color: Colors.grey),
                            border: InputBorder.none,
                            hintStyle:
                                GoogleFonts.poppins(color: Colors.grey.shade500),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ---------------- Categories ----------------
                SlideTransition(
                  position: _categorySlide,
                  child: FadeTransition(
                    opacity: _fadeIn,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Categories",
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                                color: Colors.black87)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            categoryCard("Concert", Icons.music_note,
                                [Colors.purpleAccent, Colors.deepPurple]),
                            categoryCard("Bus", Icons.directions_bus,
                                [Colors.blueAccent, Colors.blue]),
                            categoryCard(
                                "Movie",
                                Icons.movie_creation_outlined,
                                [Colors.pinkAccent, Colors.redAccent]),
                            categoryCard("Train", Icons.train,
                                [Colors.orangeAccent, Colors.deepOrange]),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // ---------------- Tickets ----------------
                FadeTransition(
                  opacity: _fadeIn,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("tickets_available")
                        .orderBy("uploadedAt", descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      final tickets = snapshot.data?.docs ?? [];
                      final filtered = selectedCategory == null
                          ? tickets
                          : tickets.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return (data["category"] ?? "")
                                  .toString()
                                  .toLowerCase()
                                  .contains(selectedCategory!.toLowerCase());
                            }).toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Text("No tickets found.",
                              style: GoogleFonts.poppins(
                                  color: Colors.grey, fontSize: 14)),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final data =
                              filtered[index].data() as Map<String, dynamic>;
                          final imageUrl =
                              getCategoryImage(data["category"] ?? "");
                          final expired = isTicketExpired(data["datetime"]);

                          return Opacity(
                            opacity: expired ? 0.5 : 1.0,
                            child: GestureDetector(
                              onTap: expired
                                  ? null
                                  : () async {
                                      final walletBalance =
                                          await getWalletBalance();
                                      final ticket = TicketModel(
                                        title: data["event"] ?? "",
                                        price: data["price"] ?? "",
                                        category: data["category"] ?? "",
                                        seller:
                                            data["uploaderEmail"] ?? "Unknown",
                                        imageUrl: imageUrl,
                                        label: "AI",
                                        date: data["datetime"] ?? "",
                                        time: data["time"] ?? "",
                                        venue: data["venue"] ?? "",
                                        seat: data["seat"] ?? "",
                                        description:
                                            data["description"] ?? "",
                                        id: filtered[index].id,
                                      );

                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => TicketPage(
                                            ticket: ticket,
                                            walletBalance: walletBalance,
                                            buyerEmail:
                                                user?.email ?? "unknown",
                                          ),
                                        ),
                                      );
                                    },
                              child: ticketCard(
                                title: data["event"] ?? "Event",
                                price: data["price"] ?? "N/A",
                                category: data["category"] ?? "",
                                seller: data["uploaderEmail"] ?? "Seller",
                                image: imageUrl,
                                date: data["datetime"] ?? "",
                                time: data["time"] ?? "",
                                venue: data["venue"] ?? "",
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------- Widgets -----------------------------

  Widget categoryCard(String title, IconData icon, List<Color> gradient) {
    final isSelected = selectedCategory == title;
    return GestureDetector(
      onTap: () => setState(() =>
          selectedCategory = isSelected ? null : title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 100,
        width: (MediaQuery.of(context).size.width - 64) / 2,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: gradient.first.withOpacity(0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(height: 8),
            Text(title,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget ticketCard({
    required String title,
    required String price,
    required String category,
    required String seller,
    required String image,
    required String date,
    required String time,
    required String venue,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child:
                Image.network(image, height: 80, width: 80, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 4),
                Text("₹$price | $category",
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color.fromARGB(255, 4, 170, 10))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 14, color: Colors.redAccent),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(venue,
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.redAccent),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 14, color: Colors.blueAccent),
                    const SizedBox(width: 4),
                    Text(date,
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.blueAccent)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
