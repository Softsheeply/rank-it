import 'package:flutter_test/flutter_test.dart';
import 'package:rank_it/models/rank_board.dart';
import 'package:rank_it/models/rank_item.dart';

void main() {
  test('ranking boards round-trip without losing item details', () {
    final board = RankBoard(
      id: 'board-1',
      title: 'Coffee shops',
      emoji: '☕',
      imagePath: '/documents/coffee.jpg',
      items: [
        RankItem(
          id: 'item-1',
          name: 'Moonbean',
          brand: 'Moonbean',
          itemName: 'Latte',
          price: '5.99',
          tier: 'S',
          pros: ['Cozy'],
        ),
      ],
    );

    final restored = RankBoard.fromJson(board.toJson());

    expect(restored.title, 'Coffee shops');
    expect(restored.imagePath, '/documents/coffee.jpg');
    expect(restored.items.single.tier, 'S');
    expect(restored.items.single.pros, ['Cozy']);
    expect(restored.items.single.brand, 'Moonbean');
    expect(restored.items.single.itemName, 'Latte');
    expect(restored.items.single.price, '5.99');
  });

  test('older saved items use their name as the brand', () {
    final item = RankItem.fromJson({'id': 'legacy', 'name': 'McDonald’s'});

    expect(item.displayBrand, 'McDonald’s');
    expect(item.itemName, isEmpty);
    expect(item.price, isEmpty);
  });
}
