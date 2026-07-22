import 'dart:convert';
import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../models/rank_board.dart';

class StorageService {
  StorageService._();
  static final instance = StorageService._();
  static const _key = 'boards';
  late Box<String> _box;

  Future<void> initialize() async {
    _box = await Hive.openBox<String>('rank_it');
  }

  List<RankBoard> loadBoards() {
    final raw = _box.get(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => RankBoard.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> saveBoards(List<RankBoard> boards) => _box.put(
    _key,
    jsonEncode(boards.map((board) => board.toJson()).toList()),
  );

  Future<String> keepImage(String sourcePath, String id) async {
    final directory = await getApplicationDocumentsDirectory();
    final extension = sourcePath.contains('.')
        ? sourcePath.substring(sourcePath.lastIndexOf('.'))
        : '.jpg';
    final saved = File('${directory.path}/rank_it_$id$extension');
    await File(sourcePath).copy(saved.path);
    return saved.path;
  }

  Future<void> deleteImage(String? path) async {
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}
