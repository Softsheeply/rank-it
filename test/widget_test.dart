import 'package:flutter_test/flutter_test.dart';
import 'package:squishling_ranker/models/rank_board.dart';
import 'package:squishling_ranker/models/rank_item.dart';

void main() {
  test('ranking boards round-trip without losing item details', () {
    final board = RankBoard(
      id: 'board-1',
      title: 'Coffee shops',
      emoji: '☕',
      items: [
        RankItem(id: 'item-1', name: 'Moonbean', tier: 'S', pros: ['Cozy']),
      ],
    );

    final restored = RankBoard.fromJson(board.toJson());

    expect(restored.title, 'Coffee shops');
    expect(restored.items.single.tier, 'S');
    expect(restored.items.single.pros, ['Cozy']);
  });
}
