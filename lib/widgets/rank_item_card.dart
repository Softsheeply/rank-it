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
  });
  final RankItem item;
  final VoidCallback? onTap;
  final bool compact;

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
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
