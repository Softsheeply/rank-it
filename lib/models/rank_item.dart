class RankItem {
  RankItem({
    required this.id,
    required this.name,
    this.brand = '',
    this.itemName = '',
    this.price = '',
    this.imagePath,
    this.tier,
    this.pros = const [],
    this.cons = const [],
    this.notes = '',
    this.location = '',
  });

  final String id;
  String name;
  String brand;
  String itemName;
  String price;
  String? imagePath;
  String? tier;
  List<String> pros;
  List<String> cons;
  String notes;
  String location;

  String get displayBrand {
    final value = brand.trim();
    return value.isNotEmpty ? value : name.trim();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'brand': brand,
    'itemName': itemName,
    'price': price,
    'imagePath': imagePath,
    'tier': tier,
    'pros': pros,
    'cons': cons,
    'notes': notes,
    'location': location,
  };

  factory RankItem.fromJson(Map<String, dynamic> json) => RankItem(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    brand: json['brand'] as String? ?? json['name'] as String? ?? '',
    itemName: json['itemName'] as String? ?? '',
    price: json['price'] as String? ?? '',
    imagePath: json['imagePath'] as String?,
    tier: json['tier'] as String?,
    pros: List<String>.from(json['pros'] ?? const []),
    cons: List<String>.from(json['cons'] ?? const []),
    notes: json['notes'] as String? ?? '',
    location: json['location'] as String? ?? '',
  );
}
