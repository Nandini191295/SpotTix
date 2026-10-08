class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String profileUrl;
  final double walletBalance;
  final List<Map<String, dynamic>> ticketsSold;
  final List<Map<String, dynamic>> ticketsBought;
  final int reports;
  final bool isBanned;
  final bool isKycVerified;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.profileUrl = '',
    this.walletBalance = 0.0,
    this.ticketsSold = const [],
    this.ticketsBought = const [],
    this.reports = 0,
    this.isBanned = false,
    this.isKycVerified = false,
  });

  int get ticketsSoldCount => ticketsSold.length;
  int get ticketsBoughtCount => ticketsBought.length;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'profileUrl': profileUrl,
      'walletBalance': walletBalance,
      'ticketsSold': ticketsSold,
      'ticketsBought': ticketsBought,
      'reports': reports,
      'isBanned': isBanned,
      'isKycVerified': isKycVerified,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      profileUrl: map['profileUrl'] ?? '',
      walletBalance: (map['walletBalance'] ?? 0).toDouble(),
      ticketsSold: List<Map<String, dynamic>>.from(map['ticketsSold'] ?? []),
      ticketsBought: List<Map<String, dynamic>>.from(map['ticketsBought'] ?? []),
      reports: map['reports'] ?? 0,
      isBanned: map['isBanned'] ?? false,
      isKycVerified: map['isKycVerified'] ?? false,
    );
  }
  UserModel copyWith({
  String? uid,
  String? name,
  String? email,
  String? phone,
  String? profileUrl,
  double? walletBalance,
  List<Map<String, dynamic>>? ticketsSold,
  List<Map<String, dynamic>>? ticketsBought,
  int? reports,
  bool? isBanned,
  bool? isKycVerified,
}) {
  return UserModel(
    uid: uid ?? this.uid,
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    profileUrl: profileUrl ?? this.profileUrl,
    walletBalance: walletBalance ?? this.walletBalance,
    ticketsSold: ticketsSold ?? this.ticketsSold,
    ticketsBought: ticketsBought ?? this.ticketsBought,
    reports: reports ?? this.reports,
    isBanned: isBanned ?? this.isBanned,
    isKycVerified: isKycVerified ?? this.isKycVerified,
  );
}

}
