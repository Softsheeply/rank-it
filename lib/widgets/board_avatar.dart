import 'dart:io';

import 'package:flutter/material.dart';

import '../models/rank_board.dart';

class BoardAvatar extends StatelessWidget {
  const BoardAvatar({
    super.key,
    required this.board,
    required this.size,
    this.borderRadius = 14,
  });

  final RankBoard board;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final path = board.imagePath;
    final hasImage = path != null && File(path).existsSync();

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF30303B),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: hasImage
          ? Image.file(File(path), width: size, height: size, fit: BoxFit.cover)
          : Text(
              board.emoji.trim().isEmpty ? '✨' : board.emoji,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: size * .52),
            ),
    );
  }
}
