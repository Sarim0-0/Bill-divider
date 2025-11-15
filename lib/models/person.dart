class Person {
  final int? id;
  final String name;

  Person({
    this.id,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory Person.fromMap(Map<String, dynamic> map) {
    return Person(
      id: map['id'] as int?,
      name: map['name'] as String,
    );
  }

  Person copyWith({
    int? id,
    String? name,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}











