import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/rank_board.dart';
import '../models/rank_item.dart';
import '../widgets/rank_item_card.dart';
import '../widgets/tier_badge.dart';
import 'item_detail_screen.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key, required this.board, required this.onChanged});
  final RankBoard board;
  final VoidCallback onChanged;

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  Future<void> _open(RankItem item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
    );
    setState(() {});
    widget.onChanged();
  }

  Future<void> _add() async {
    final item = RankItem(id: const Uuid().v4(), name: 'New favorite');
    widget.board.items.add(item);
    await _open(item);
  }

  void _move(RankItem item, String? tier) {
    setState(() => item.tier = tier);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('${widget.board.emoji}  ${widget.board.title}')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _add,
      icon: const Icon(Icons.add),
      label: const Text('Add item'),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      children: [
        Text(
          '${widget.board.items.length} contenders',
          style: TextStyle(color: Colors.white.withValues(alpha: .55)),
        ),
        const SizedBox(height: 14),
        ...['S', 'A', 'B', 'C', 'D', 'F'].map(
          (tier) => _TierRow(
            tier: tier,
            items: widget.board.items
                .where((item) => item.tier == tier)
                .toList(),
            onAccept: (item) => _move(item, tier),
            onTap: _open,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'UNRANKED',
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w800,
            color: Colors.white54,
          ),
        ),
        const SizedBox(height: 10),
        DragTarget<RankItem>(
          onAcceptWithDetails: (details) => _move(details.data, null),
          builder: (_, __, ___) => Wrap(
            spacing: 10,
            runSpacing: 10,
            children: widget.board.items
                .where((item) => item.tier == null)
                .map(
                  (item) => LongPressDraggable<RankItem>(
                    data: item,
                    feedback: Material(
                      color: Colors.transparent,
                      child: RankItemCard(item: item, compact: true),
                    ),
                    childWhenDragging: Opacity(
                      opacity: .25,
                      child: RankItemCard(item: item, compact: true),
                    ),
                    child: RankItemCard(
                      item: item,
                      compact: true,
                      onTap: () => _open(item),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    ),
  );
}

class _TierRow extends StatelessWidget {
  const _TierRow({
    required this.tier,
    required this.items,
    required this.onAccept,
    required this.onTap,
  });
  final String tier;
  final List<RankItem> items;
  final ValueChanged<RankItem> onAccept;
  final ValueChanged<RankItem> onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: DragTarget<RankItem>(
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (_, candidates, __) => AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 92),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: candidates.isNotEmpty
              ? tierColors[tier]!.withValues(alpha: .18)
              : const Color(0xFF1C1C24),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: candidates.isNotEmpty ? tierColors[tier]! : Colors.white10,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TierBadge(tier, size: 54),
            const SizedBox(width: 10),
            Expanded(
              child: items.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 17),
                      child: Text(
                        'Drop here',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .3),
                        ),
                      ),
                    )
                  : SizedBox(
                      height: 116,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, index) {
                          final item = items[index];
                          return LongPressDraggable<RankItem>(
                            data: item,
                            feedback: Material(
                              color: Colors.transparent,
                              child: RankItemCard(item: item, compact: true),
                            ),
                            childWhenDragging: Opacity(
                              opacity: .25,
                              child: RankItemCard(item: item, compact: true),
                            ),
                            child: RankItemCard(
                              item: item,
                              compact: true,
                              onTap: () => onTap(item),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}
