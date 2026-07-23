import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../main.dart' show purchaseService;
import '../models/rank_board.dart';
import '../models/rank_item.dart';
import '../services/ads_service.dart';
import '../widgets/rank_item_card.dart';
import '../widgets/tier_badge.dart';
import 'item_detail_screen.dart';
import '../services/storage_service.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key, required this.board, required this.onChanged});
  final RankBoard board;
  final VoidCallback onChanged;

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  Future<String?> _open(RankItem item) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
    );
    if (result == 'delete') {
      await StorageService.instance.deleteImage(item.imagePath);
      widget.board.items.remove(item);
    }
    setState(() {});
    widget.onChanged();
    return result;
  }

  Future<void> _add() async {
    final item = RankItem(id: const Uuid().v4(), name: '');
    widget.board.items.add(item);
    final result = await _open(item);
    if (result == null && widget.board.items.contains(item)) {
      await StorageService.instance.deleteImage(item.imagePath);
      setState(() => widget.board.items.remove(item));
      widget.onChanged();
    }
  }

  Future<void> _deleteAllItems() async {
    if (widget.board.items.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete all items?'),
        content: Text(
          'This permanently deletes all ${widget.board.items.length} items in this ranking.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete all'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    for (final item in widget.board.items) {
      await StorageService.instance.deleteImage(item.imagePath);
    }
    setState(widget.board.items.clear);
    widget.onChanged();
  }

  void _move(RankItem item, String? tier) {
    setState(() => item.tier = tier);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('${widget.board.emoji}  ${widget.board.title}'),
      actions: [
        PopupMenuButton<String>(
          onSelected: (_) => _deleteAllItems(),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'deleteAll', child: Text('Delete all items')),
          ],
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _add,
      icon: const Icon(Icons.add),
      label: const Text('Add item'),
    ),
    bottomNavigationBar: BannerAdBar(purchaseService: purchaseService),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      children: [
        Text(
          '${widget.board.items.length} contenders • Hold and drag to rank',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: .55),
          ),
        ),
        const SizedBox(height: 8),
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
          builder: (_, _, _) => Wrap(
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
    padding: const EdgeInsets.only(bottom: 6),
    child: DragTarget<RankItem>(
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (_, candidates, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.all(6),
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
            TierBadge(tier, size: 44),
            const SizedBox(width: 7),
            Expanded(
              child: items.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 11),
                      child: Text(
                        'Drop here',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .3),
                        ),
                      ),
                    )
                  : SizedBox(
                      height: 78,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
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
