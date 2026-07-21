import 'rank_item.dart';

class RankBoard {
  RankBoard({
    required this.id,
    required this.title,
    required this.emoji,
    List<RankItem>? items,
  }) : items = items ?? [];

  final String id;
  String title;
  String emoji;
  final List<RankItem> items;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'emoji': emoji,
    'items': items.map((item) => item.toJson()).toList(),
  };

  factory RankBoard.fromJson(Map<String, dynamic> json) => RankBoard(
    id: json['id'] as String,
    title: json['title'] as String,
    emoji: json['emoji'] as String? ?? '✨',
    items: (json['items'] as List? ?? const [])
        .map(
          (item) => RankItem.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
  );
}
