class PurchaseModel {
  final String buyerId;
  final String ticketId;
  final double amount;
  final DateTime purchaseDate;

  PurchaseModel({
    required this.buyerId,
    required this.ticketId,
    required this.amount,
    required this.purchaseDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'buyerId': buyerId,
      'ticketId': ticketId,
      'amount': amount,
      'purchaseDate': purchaseDate.toIso8601String(),
    };
  }

  factory PurchaseModel.fromMap(Map<String, dynamic> map) {
    return PurchaseModel(
      buyerId: map['buyerId'] ?? '',
      ticketId: map['ticketId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      purchaseDate: DateTime.tryParse(map['purchaseDate'] ?? '') ?? DateTime.now(),
    );
  }
}
