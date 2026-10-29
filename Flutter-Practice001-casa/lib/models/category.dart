class Category {
  final int? id;
  final String name;
  final int version;

  Category({
    this.id,
    required this.name,
    this.version = 1,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
      version: json['version'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id ?? 0,
      'name': name,
      'version': version,
    };
  }

  Category copyWith({
    int? id,
    String? name,
    int? version,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
    );
  }
}
