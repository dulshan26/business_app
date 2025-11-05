class CardModel {
  final String id; // e.g. 'dfcc'
  final double limit;
  final String lastDigits;
  final String status; // 'active' or 'closed'
  final String notes;

  CardModel({
    required this.id,
    required this.limit,
    required this.lastDigits,
    required this.status,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'limit': limit,
      'lastDigits': lastDigits,
      'status': status,
      'notes': notes,
    };
  }

  factory CardModel.fromMap(Map<String, dynamic> map) {
    return CardModel(
      id: map['id'] ?? '',
      limit: (map['limit'] ?? 0).toDouble(),
      lastDigits: map['lastDigits'] ?? '',
      status: map['status'] ?? 'active',
      notes: map['notes'] ?? '',
    );
  }
  List<CardModel> cardData = [
    CardModel(
      id: 'dfcc',
      limit: 100000,
      lastDigits: '1234',
      status: 'active',
      notes: 'My DFCC card',
    ),
    CardModel(
      id: 'hnb',
      limit: 200000,
      lastDigits: '5678',
      status: 'active',
      notes: 'My HNB card',
    ),
  ];
}
