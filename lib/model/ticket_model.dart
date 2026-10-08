class TicketModel {
  final String id;
  final String title;
  final String price;
  final String category;
  final String seller;
  final String imageUrl;
  final String label;
  final String date;
  final String time;
  final String venue;
  final String seat;
  final String description;
  final String status; // available, sold, pending
  final String? buyerId;

  TicketModel({
    required this.id,
    required this.title,
    required this.price,
    required this.category,
    required this.seller,
    required this.imageUrl,
    required this.label,
    required this.date,
    required this.time,
    required this.venue,
    required this.seat,
    required this.description,
    this.status = 'available',
    this.buyerId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'category': category,
      'seller': seller,
      'imageUrl': imageUrl,
      'label': label,
      'date': date,
      'time': time,
      'venue': venue,
      'seat': seat,
      'description': description,
      'status': status,
      'buyerId': buyerId,
    };
  }

  factory TicketModel.fromMap(Map<String, dynamic> map) {
    return TicketModel(
      id: map['id'] ?? '',
    title: map['event'] ?? '', // changed here
    price: map['price'] ?? '',
    category: map['category'] ?? '',
    seller: map['uploader'] ?? '',
    imageUrl: map['image'] ?? '',
    label: map['label'] ?? '',
    date: map['datetime'] ?? '', // changed here
    time: '', // since Firestore only stores datetime
    venue: map['venue'] ?? '',
    seat: map['seat'] ?? '',
    description: map['description'] ?? '',
    status: map['status'] ?? 'available',
    buyerId: map['buyerId'],
    );
  }
}