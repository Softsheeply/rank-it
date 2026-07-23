import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../models/rank_board.dart';
import '../services/storage_service.dart';

enum _CoverType { emoji, photo }

class NewBoardScreen extends StatefulWidget {
  const NewBoardScreen({super.key});

  @override
  State<NewBoardScreen> createState() => _NewBoardScreenState();
}

class _NewBoardScreenState extends State<NewBoardScreen> {
  final title = TextEditingController();
  final emoji = TextEditingController(text: '🍽️');
  final picker = ImagePicker();
  final boardId = const Uuid().v4();

  _CoverType coverType = _CoverType.emoji;
  String? imagePath;
  bool saving = false;

  @override
  void dispose() {
    title.dispose();
    emoji.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final image = await picker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 1600,
      );
      if (image == null || !mounted) return;
      setState(() {
        imagePath = image.path;
        coverType = _CoverType.photo;
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      final isPermissionError =
          error.code.toLowerCase().contains('access') ||
          error.code.toLowerCase().contains('permission');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPermissionError
                ? 'Please allow photo access in Settings, then try again.'
                : 'That picture could not be opened. Please try another.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('That picture could not be opened. Please try again.'),
        ),
      );
    }
  }

  Future<void> _create() async {
    if (saving) return;
    if (title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give your ranking a name first.')),
      );
      return;
    }
    if (coverType == _CoverType.photo && imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose or take a picture first.')),
      );
      return;
    }

    setState(() => saving = true);
    String? savedImagePath;
    try {
      if (coverType == _CoverType.photo) {
        savedImagePath = await StorageService.instance.keepImage(
          imagePath!,
          'board_$boardId',
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The picture could not be saved. Please try again.'),
        ),
      );
      return;
    }
    if (!mounted) return;

    Navigator.pop(
      context,
      RankBoard(
        id: boardId,
        title: title.text.trim(),
        emoji: emoji.text.trim().isEmpty ? '✨' : emoji.text.trim(),
        imagePath: savedImagePath,
      ),
    );
  }

  Widget _coverPreview() {
    final hasPhoto =
        coverType == _CoverType.photo &&
        imagePath != null &&
        File(imagePath!).existsSync();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 116,
      height: 116,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF30303B),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFFF6B5F), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: hasPhoto
          ? Image.file(
              File(imagePath!),
              width: 116,
              height: 116,
              fit: BoxFit.cover,
            )
          : Text(
              emoji.text.trim().isEmpty ? '✨' : emoji.text.trim(),
              textAlign: TextAlign.center,
              maxLines: 1,
              style: const TextStyle(fontSize: 56),
            ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('New ranking'),
      actions: [
        TextButton(
          onPressed: saving ? null : _create,
          child: saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    ),
    body: SafeArea(
      top: false,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          22,
          10,
          22,
          MediaQuery.viewInsetsOf(context).bottom + 32,
        ),
        children: [
          const Text(
            'Create a ranking',
            style: TextStyle(fontSize: 29, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Give your list a name and a cover that feels like yours.',
            style: TextStyle(color: Colors.white.withValues(alpha: .55)),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: title,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Ranking name',
              hintText: 'Best burgers in Toronto',
              prefixIcon: Icon(Icons.format_list_numbered_rounded),
            ),
          ),
          const SizedBox(height: 26),
          const Text(
            'Cover',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Center(child: _coverPreview()),
          const SizedBox(height: 18),
          SegmentedButton<_CoverType>(
            segments: const [
              ButtonSegment(
                value: _CoverType.emoji,
                icon: Icon(Icons.emoji_emotions_outlined),
                label: Text('Emoji'),
              ),
              ButtonSegment(
                value: _CoverType.photo,
                icon: Icon(Icons.photo_outlined),
                label: Text('Picture'),
              ),
            ],
            selected: {coverType},
            showSelectedIcon: false,
            onSelectionChanged: (selection) {
              FocusScope.of(context).unfocus();
              setState(() => coverType = selection.first);
            },
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: coverType == _CoverType.emoji
                ? TextField(
                    key: const ValueKey('emoji'),
                    controller: emoji,
                    textAlign: TextAlign.center,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 30),
                    decoration: const InputDecoration(
                      labelText: 'Your emoji',
                      hintText: 'Use the emoji keyboard',
                      helperText: 'Pick any emoji available on your phone',
                      prefixIcon: Icon(Icons.emoji_emotions_outlined),
                    ),
                  )
                : Container(
                    key: const ValueKey('photo'),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF24242D),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          imagePath == null
                              ? 'Add a picture for this ranking'
                              : 'Picture selected',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.tonalIcon(
                                onPressed: () =>
                                    _pickPhoto(ImageSource.gallery),
                                icon: const Icon(Icons.photo_library_outlined),
                                label: Text(
                                  imagePath == null ? 'Photos' : 'Change',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.tonalIcon(
                                onPressed: () => _pickPhoto(ImageSource.camera),
                                icon: const Icon(Icons.camera_alt_outlined),
                                label: const Text('Camera'),
                              ),
                            ),
                          ],
                        ),
                        if (imagePath != null) ...[
                          const SizedBox(height: 6),
                          TextButton.icon(
                            onPressed: () => setState(() => imagePath = null),
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Remove picture'),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: saving ? null : _create,
            icon: const Icon(Icons.add),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(saving ? 'Saving…' : 'Create ranking'),
            ),
          ),
        ],
      ),
    ),
  );
}
