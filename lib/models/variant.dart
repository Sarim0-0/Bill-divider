class Variant {
  final int? id;
  final int itemId;
  final String name;
  final double price;

  Variant({
    this.id,
    required this.itemId,
    required this.name,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_id': itemId,
      'name': name,
      'price': price,
    };
  }

  factory Variant.fromMap(Map<String, dynamic> map) {
    return Variant(
      id: map['id'] as int?,
      itemId: map['item_id'] as int,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
    );
  }

  Variant copyWith({
    int? id,
    int? itemId,
    String? name,
    double? price,
  }) {
    return Variant(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      price: price ?? this.price,
    );
  }
}












