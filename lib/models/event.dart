class Event {
  final int? id;
  final String name;
  final String date; // ISO 8601 format (YYYY-MM-DD)

  Event({
    this.id,
    required this.name,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date': date,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'] as int?,
      name: map['name'] as String,
      date: map['date'] as String,
    );
  }

  Event copyWith({
    int? id,
    String? name,
    String? date,
  }) {
    return Event(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
    );
  }
}









