class Product {
  final int? id;
  final String names;
  final String description;
  final double price;
  final int stock;
  final bool isActive;
  final int version;
  final String? imageUrl;

  Product({
    this.id,
    required this.names,
    required this.description,
    required this.price,
    required this.stock,
    this.isActive = true,
    this.version = 1,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      names: json['names'] as String,
      description: json['descriptions'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      stock: json['stock'] as int,
      isActive: json['isActive'] as bool? ?? true,
      version: json['version'] as int? ?? 1,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id ?? 0,
      'names': names,
      'descriptions': description,
      'price': price,
      'stock': stock,
      'isActive': isActive,
      'version': version,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  Product copyWith({
    int? id,
    String? names,
    String? description,
    double? price,
    int? stock,
    bool? isActive,
    int? version,
    String? imageUrl,
  }) {
      return Product(
      id: id??this.id,
      names: names ?? this.names,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      isActive: isActive ?? this.isActive,
      version: version ?? this.version,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}