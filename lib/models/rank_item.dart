class RankItem {
  RankItem({
    required this.id,
    required this.name,
    this.imagePath,
    this.tier,
    this.pros = const [],
    this.cons = const [],
    this.notes = '',
    this.location = '',
  });

  final String id;
  String name;
  String? imagePath;
  String? tier;
  List<String> pros;
  List<String> cons;
  String notes;
  String location;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'imagePath': imagePath,
    'tier': tier,
    'pros': pros,
    'cons': cons,
    'notes': notes,
    'location': location,
  };

  factory RankItem.fromJson(Map<String, dynamic> json) => RankItem(
    id: json['id'] as String,
    name: json['name'] as String,
    imagePath: json['imagePath'] as String?,
    tier: json['tier'] as String?,
    pros: List<String>.from(json['pros'] ?? const []),
    cons: List<String>.from(json['cons'] ?? const []),
    notes: json['notes'] as String? ?? '',
    location: json['location'] as String? ?? '',
  );
}
