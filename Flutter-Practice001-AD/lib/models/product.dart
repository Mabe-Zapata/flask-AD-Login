class Product {
  final int? id;
  final String names;
  final double price;
  final int stock;
  final int version;
  final String? descriptions;
  final String? imageUrl;
  final bool isActive;

  Product({
    this.id,
    required this.names,
    required this.price,
    required this.stock,
    this.version = 1,
    this.descriptions,
    this.imageUrl,
    this.isActive = true,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      names: json['names'] as String,
      price: (json['price'] as num).toDouble(),
      stock: json['stock'] as int,
      version: json['version'] as int? ?? 1,
      descriptions: json['descriptions'] as String?,
      imageUrl: json['imageUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id ?? 0,
      'names': names,
      'price': price,
      'stock': stock,
      'version': version,
      // shortcut: el backend exige estos strings; se envían valores por defecto si no hay datos.
      'descriptions': descriptions ?? 'Sin descripción',
      'imageUrl': imageUrl ?? 'Sin imagen',
      'isActive': isActive,
    };
  }

  Product copyWith({
    int? id,
    String? names,
    double? price,
    int? stock,
    int? version,
    String? descriptions,
    String? imageUrl,
    bool? isActive,
  }) {
    return Product(
      id: id ?? this.id,
      names: names ?? this.names,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      version: version ?? this.version,
      descriptions: descriptions ?? this.descriptions,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
    );
  }
}