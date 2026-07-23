import 'package:flutter/material.dart';

import '../main.dart' show purchaseService;
import '../models/rank_board.dart';
import '../models/rank_item.dart';
import '../services/ads_service.dart';
import '../services/purchase_service.dart';
import '../services/storage_service.dart';
import '../widgets/rank_item_card.dart';
import 'board_screen.dart';
import 'new_board_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<RankBoard> boards;

  @override
  void initState() {
    super.initState();
    boards = StorageService.instance.loadBoards();
    var migratedEmoji = false;
    for (final board in boards) {
      final title = board.title.toLowerCase();
      if (board.emoji == '🍜' &&
          (title.contains('burger') || title.contains('chicken'))) {
        board.emoji = '🍔';
        migratedEmoji = true;
      }
    }
    if (migratedEmoji) {
      StorageService.instance.saveBoards(boards);
    }
    purchaseService.addListener(_onPurchaseChanged);
  }

  @override
  void dispose() {
    purchaseService.removeListener(_onPurchaseChanged);
    super.dispose();
  }

  void _onPurchaseChanged() {
    if (mounted) setState(() {});
  }

  void _showRemoveAdsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _RemoveAdsSheet(purchaseService: purchaseService),
    );
  }

  Future<void> _save() => StorageService.instance.saveBoards(boards);

  Future<void> _newBoard() async {
    final board = await Navigator.push<RankBoard>(
      context,
      MaterialPageRoute(builder: (_) => const NewBoardScreen()),
    );
    if (board == null) return;
    setState(() => boards.add(board));
    await _save();
    if (!mounted) return;
    _open(board);
  }

  Future<void> _deleteBoard(RankBoard board) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${board.title}?'),
        content: Text(
          'This permanently deletes the ranking and all ${board.items.length} items in it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    for (final item in board.items) {
      await StorageService.instance.deleteImage(item.imagePath);
    }
    setState(() => boards.remove(board));
    await _save();
  }

  void _open(RankBoard board) {
    InterstitialAdManager.instance.maybeShowOnOpen(
      adsRemoved: purchaseService.adsRemoved,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BoardScreen(
          board: board,
          onChanged: () {
            _save();
            setState(() {});
          },
        ),
      ),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final favorites = <(RankItem, RankBoard)>[
      for (final board in boards)
        for (final item in board.items.where((item) => item.tier == 'S'))
          (item, board),
    ];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 16),
                    sliver: SliverList.list(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B5F),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Text(
                                'S',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'RANK IT',
                                    style: TextStyle(
                                      fontSize: 12,
                                      letterSpacing: 2,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFFF8A80),
                                    ),
                                  ),
                                  Text(
                                    'From best to worst.',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!purchaseService.adsRemoved)
                              IconButton(
                                icon: const Icon(Icons.block_rounded),
                                tooltip: 'Remove Ads',
                                onPressed: _showRemoveAdsSheet,
                              ),
                            IconButton.filled(
                              onPressed: _newBoard,
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                        const SizedBox(height: 34),
                        const Text(
                          'S–Tier favorites',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'The best of the best, across every list.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (favorites.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C1C24),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  color: Color(0xFFFF6B5F),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Your S–Tier picks will glow here. Create a ranking to get started.',
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          SizedBox(
                            height: 138,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: favorites.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (_, index) {
                                final (item, board) = favorites[index];
                                return RankItemCard(
                                  item: item,
                                  compact: true,
                                  boardLabel: '${board.emoji} ${board.title}',
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 34),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Your rankings',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '${boards.length}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (boards.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: FilledButton.icon(
                          onPressed: _newBoard,
                          icon: const Icon(Icons.add),
                          label: const Text('Create your first ranking'),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.96,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        delegate: SliverChildBuilderDelegate((_, index) {
                          final board = boards[index];
                          return Stack(
                            children: [
                              Positioned.fill(
                                child: InkWell(
                                  onTap: () => _open(board),
                                  borderRadius: BorderRadius.circular(24),
                                  child: Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1C1C24),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          board.emoji,
                                          style: const TextStyle(fontSize: 34),
                                        ),
                                        const Spacer(),
                                        Text(
                                          board.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          '${board.items.length} items',
                                          style: const TextStyle(
                                            color: Colors.white54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: PopupMenuButton<String>(
                                  tooltip: 'Ranking options',
                                  onSelected: (_) => _deleteBoard(board),
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete_outline,
                                            color: Colors.redAccent,
                                          ),
                                          SizedBox(width: 10),
                                          Text('Delete ranking'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }, childCount: boards.length),
                      ),
                    ),
                ],
              ),
            ),
            BannerAdBar(purchaseService: purchaseService),
          ],
        ),
      ),
    );
  }
}

class _RemoveAdsSheet extends StatelessWidget {
  final PurchaseService purchaseService;
  const _RemoveAdsSheet({required this.purchaseService});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: purchaseService,
      builder: (context, _) {
        final product = purchaseService.removeAdsProduct;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.block_rounded,
                  size: 40,
                  color: Color(0xFFFF6B5F),
                ),
                const SizedBox(height: 12),
                Text(
                  purchaseService.adsRemoved
                      ? 'Ads are removed 🎉'
                      : 'Remove Ads',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  purchaseService.adsRemoved
                      ? 'Thanks for supporting Rank It!'
                      : 'A one-time purchase removes all banner and interstitial ads, forever.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                if (!purchaseService.adsRemoved) ...[
                  FilledButton(
                    onPressed:
                        purchaseService.purchasePending || product == null
                        ? null
                        : purchaseService.buyRemoveAds,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        purchaseService.purchasePending
                            ? 'Processing…'
                            : product != null
                            ? 'Remove Ads — ${product.price}'
                            : 'Remove Ads — \$1.99',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: purchaseService.restorePurchases,
                    child: const Text('Restore Purchases'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
