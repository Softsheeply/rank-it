import 'package:flutter/material.dart';

import '../models/rank_board.dart';
import '../models/rank_item.dart';
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

  void _open(RankBoard board) => Navigator.push(
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

  @override
  Widget build(BuildContext context) {
    final favorites = <RankItem>[
      for (final board in boards)
        ...board.items.where((item) => item.tier == 'S'),
    ];
    return Scaffold(
      body: SafeArea(
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
                      IconButton.filled(
                        onPressed: _newBoard,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),
                  const Text(
                    'S–Tier favorites',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'The best of the best, across every list.',
                    style: TextStyle(color: Colors.white.withValues(alpha: .5)),
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
                          Icon(Icons.auto_awesome, color: Color(0xFFFF6B5F)),
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
                      height: 122,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: favorites.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, index) =>
                            RankItemCard(item: favorites[index], compact: true),
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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.96,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate((_, index) {
                    final board = boards[index];
                    return InkWell(
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
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                              style: const TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      ),
                    );
                  }, childCount: boards.length),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
