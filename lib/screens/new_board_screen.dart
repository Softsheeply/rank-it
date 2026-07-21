import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/rank_board.dart';

class NewBoardScreen extends StatefulWidget {
  const NewBoardScreen({super.key});
  @override
  State<NewBoardScreen> createState() => _NewBoardScreenState();
}

class _NewBoardScreenState extends State<NewBoardScreen> {
  final title = TextEditingController();
  String emoji = '🍜';
  final emojis = ['🍜', '🎬', '🎮', '☕', '📚', '✈️', '🎵', '👟', '✨'];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('New ranking'),
      actions: [
        TextButton(
          onPressed: () {
            if (title.text.trim().isEmpty) return;
            Navigator.pop(
              context,
              RankBoard(
                id: const Uuid().v4(),
                title: title.text.trim(),
                emoji: emoji,
              ),
            );
          },
          child: const Text('Create'),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'What are we ranking?',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: title,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Board name',
            hintText: 'Best ramen in Toronto',
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Pick a vibe',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: emojis
              .map(
                (value) => ChoiceChip(
                  label: Text(value, style: const TextStyle(fontSize: 24)),
                  selected: emoji == value,
                  onSelected: (_) => setState(() => emoji = value),
                ),
              )
              .toList(),
        ),
      ],
    ),
  );
}
