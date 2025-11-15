class Item {
  final int? id;
  final int eventId;
  final String name;
  final double price;

  Item({
    this.id,
    required this.eventId,
    required this.name,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_id': eventId,
      'name': name,
      'price': price,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] as int?,
      eventId: map['event_id'] as int,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
    );
  }

  Item copyWith({
    int? id,
    int? eventId,
    String? name,
    double? price,
  }) {
    return Item(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      name: name ?? this.name,
      price: price ?? this.price,
    );
  }
}












