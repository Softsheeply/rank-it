import 'dart:io';

import 'package:flutter/material.dart';

import '../models/rank_item.dart';

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
    final displayBrand = item.displayBrand;
    final showBoardLabel = boardLabel != null;
    final cardWidth = showBoardLabel ? 118.0 : (compact ? 82.0 : 118.0);
    final imageHeight = showBoardLabel ? 80.0 : (compact ? 50.0 : 102.0);
    final image = item.imagePath != null && File(item.imagePath!).existsSync()
        ? Image.file(File(item.imagePath!), fit: BoxFit.cover)
        : Container(
            color: const Color(0xFF30303B),
            alignment: Alignment.center,
            child: Text(
              displayBrand.isEmpty
                  ? '?'
                  : displayBrand.characters.first.toUpperCase(),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
          );
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(
          color: const Color(0xFF24242D),
          borderRadius: BorderRadius.circular(18),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: imageHeight, child: image),
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact && !showBoardLabel ? 7 : 10,
                compact && !showBoardLabel ? 4 : 7,
                compact && !showBoardLabel ? 7 : 10,
                compact && !showBoardLabel ? 5 : 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayBrand,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textScaler: const TextScaler.linear(1),
                    style: TextStyle(
                      fontSize: compact && !showBoardLabel ? 12 : 14,
                      height: 1.05,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (item.location.isNotEmpty && boardLabel == null)
                    Text(
                      item.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textScaler: const TextScaler.linear(1),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: .5),
                      ),
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
