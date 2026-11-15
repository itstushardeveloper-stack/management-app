class Hall {
  final int? id;
  final String name;
  final int capacity;
  final double basePrice;
  final String? description;
  final String? amenities;
  final bool isActive;

  Hall({
    this.id,
    required this.name,
    required this.capacity,
    required this.basePrice,
    this.description,
    this.amenities,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'capacity': capacity,
      'base_price': basePrice,
      'description': description,
      'amenities': amenities,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory Hall.fromMap(Map<String, dynamic> map) {
    return Hall(
      id: map['id'] as int?,
      name: map['name'] as String,
      capacity: map['capacity'] as int,
      basePrice: (map['base_price'] as num).toDouble(),
      description: map['description'] as String?,
      amenities: map['amenities'] as String?,
      isActive: (map['is_active'] as int? ?? 1) == 1,
    );
  }

  Hall copyWith({
    int? id,
    String? name,
    int? capacity,
    double? basePrice,
    String? description,
    String? amenities,
    bool? isActive,
  }) {
    return Hall(
      id: id ?? this.id,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      basePrice: basePrice ?? this.basePrice,
      description: description ?? this.description,
      amenities: amenities ?? this.amenities,
      isActive: isActive ?? this.isActive,
    );
  }
}

