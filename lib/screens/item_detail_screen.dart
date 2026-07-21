import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

  Future<void> _photo() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
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
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Rank item'),
      actions: [TextButton(onPressed: _save, child: const Text('Save'))],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
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
            child: const Column(
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
          decoration: const InputDecoration(
            labelText: 'Pros',
            hintText: 'One per line',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: cons,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Cons',
            hintText: 'One per line',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: notes,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(labelText: 'Notes'),
        ),
      ],
    ),
  );
}
