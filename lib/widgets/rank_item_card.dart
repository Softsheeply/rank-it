import 'dart:io';

import 'package:flutter/material.dart';

import '../models/rank_item.dart';
import 'tier_badge.dart';

class RankItemCard extends StatelessWidget {
  const RankItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.compact = false,
    this.boardLabel,
  });
  final RankItem item;
  final VoidCallback? onTap;
  final bool compact;

  /// Optional board name (e.g. "🍔 Chicken Burgers") shown under the item
  /// name — used on the home screen's cross-board favorites row so it's
  /// clear which ranking each S-tier pick came from.
  final String? boardLabel;

  @override
  Widget build(BuildContext context) {
    final image = item.imagePath != null && File(item.imagePath!).existsSync()
        ? Image.file(File(item.imagePath!), fit: BoxFit.cover)
        : Container(
            color: const Color(0xFF30303B),
            alignment: Alignment.center,
            child: Text(
              item.name.isEmpty
                  ? '?'
                  : item.name.characters.first.toUpperCase(),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
          );
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: compact ? 92 : 118,
        decoration: BoxDecoration(
          color: const Color(0xFF24242D),
          borderRadius: BorderRadius.circular(18),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1.15,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  image,
                  if (item.tier != null)
                    Positioned(
                      top: 7,
                      right: 7,
                      child: TierBadge(item.tier!, size: 28),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textScaler: const TextScaler.linear(1),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (boardLabel != null)
                    Text(
                      boardLabel!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textScaler: const TextScaler.linear(1),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: .5),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
