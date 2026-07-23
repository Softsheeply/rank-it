import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../models/rank_item.dart';
import '../services/storage_service.dart';
import '../widgets/tier_badge.dart';

class ItemDetailScreen extends StatefulWidget {
  const ItemDetailScreen({super.key, required this.item});
  final RankItem item;

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late final TextEditingController name;
  late final TextEditingController pros;
  late final TextEditingController cons;
  late final TextEditingController notes;
  late final TextEditingController location;
  final SpeechToText speech = SpeechToText();
  TextEditingController? listeningTo;
  String dictationBase = '';
  String? tier;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    name = TextEditingController(text: item.name);
    pros = TextEditingController(text: item.pros.join('\n'));
    cons = TextEditingController(text: item.cons.join('\n'));
    notes = TextEditingController(text: item.notes);
    location = TextEditingController(text: item.location);
    tier = item.tier;
  }

  @override
  void dispose() {
    speech.stop();
    name.dispose();
    pros.dispose();
    cons.dispose();
    notes.dispose();
    location.dispose();
    super.dispose();
  }

  Future<void> _photo() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Library'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final image = await ImagePicker().pickImage(
      source: source,
      imageQuality: 88,
    );
    if (image == null) return;
    widget.item.imagePath = await StorageService.instance.keepImage(
      image.path,
      widget.item.id,
    );
    setState(() {});
  }

  void _save() {
    widget.item
      ..name = name.text.trim()
      ..pros = pros.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList()
      ..cons = cons.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList()
      ..notes = notes.text.trim()
      ..location = location.text.trim()
      ..tier = tier;
    Navigator.pop(context, 'saved');
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this item?'),
        content: const Text('This cannot be undone.'),
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
    if (confirmed == true && mounted) Navigator.pop(context, 'delete');
  }

  Future<void> _dictate(TextEditingController controller) async {
    if (speech.isListening) {
      await speech.stop();
      if (listeningTo == controller) {
        setState(() => listeningTo = null);
        return;
      }
    }
    final available = await speech.initialize(
      onStatus: (status) {
        if (status == 'notListening' || status == 'done') {
          if (mounted) setState(() => listeningTo = null);
        }
      },
      onError: (_) {
        if (mounted) setState(() => listeningTo = null);
      },
    );
    if (!available) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition is not available on this device.'),
        ),
      );
      return;
    }
    dictationBase = controller.text.trimRight();
    setState(() => listeningTo = controller);
    await speech.listen(
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        partialResults: true,
      ),
      onResult: (result) {
        final separator = dictationBase.isEmpty ? '' : '\n';
        controller.text = '$dictationBase$separator${result.recognizedWords}';
        controller.selection = TextSelection.collapsed(
          offset: controller.text.length,
        );
      },
    );
  }

  InputDecoration _dictationDecoration({
    required String label,
    String? hint,
    required TextEditingController controller,
  }) => InputDecoration(
    labelText: label,
    hintText: hint,
    suffixIcon: IconButton(
      tooltip: listeningTo == controller ? 'Stop dictating' : 'Dictate $label',
      onPressed: () => _dictate(controller),
      color: listeningTo == controller ? const Color(0xFFFF6B5F) : null,
      icon: Icon(
        listeningTo == controller ? Icons.stop_circle : Icons.mic_none,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Rank item'),
      actions: [
        IconButton(
          onPressed: _delete,
          tooltip: 'Delete item',
          icon: const Icon(Icons.delete_outline),
        ),
        TextButton(onPressed: _save, child: const Text('Save')),
      ],
    ),
    body: SafeArea(
      top: false,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 40,
        ),
        children: [
          InkWell(
            onTap: _photo,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              height: 170,
              decoration: BoxDecoration(
                color: const Color(0xFF24242D),
                borderRadius: BorderRadius.circular(24),
              ),
              clipBehavior: Clip.antiAlias,
              child:
                  widget.item.imagePath != null &&
                      File(widget.item.imagePath!).existsSync()
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          File(widget.item.imagePath!),
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: .7),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.photo_library_outlined, size: 18),
                                  SizedBox(width: 6),
                                  Text('Change photo'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, size: 38),
                        SizedBox(height: 10),
                        Text('Choose a photo'),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 18),
          const Text(
            'Your verdict',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: ['S', 'A', 'B', 'C', 'D', 'F']
                .map(
                  (value) => GestureDetector(
                    onTap: () => setState(() => tier = value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: EdgeInsets.all(tier == value ? 4 : 0),
                      decoration: BoxDecoration(
                        border: tier == value
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: TierBadge(value),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: location,
            decoration: const InputDecoration(
              labelText: 'Location',
              prefixIcon: Icon(Icons.place_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: pros,
            minLines: 2,
            maxLines: 4,
            decoration: _dictationDecoration(
              label: 'Pros',
              hint: 'One per line',
              controller: pros,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: cons,
            minLines: 2,
            maxLines: 4,
            decoration: _dictationDecoration(
              label: 'Cons',
              hint: 'One per line',
              controller: cons,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: notes,
            minLines: 3,
            maxLines: 6,
            decoration: _dictationDecoration(label: 'Notes', controller: notes),
          ),
        ],
      ),
    ),
  );
}
