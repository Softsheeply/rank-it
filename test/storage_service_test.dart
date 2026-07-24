import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:rank_it/models/rank_board.dart';
import 'package:rank_it/models/rank_item.dart';
import 'package:rank_it/services/storage_service.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  final Directory dir;
  _FakePathProviderPlatform(this.dir);

  @override
  Future<String?> getApplicationDocumentsPath() async => dir.path;
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('rank_it_storage_test');
    Hive.init(tempDir.path);
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir);
    await StorageService.instance.initialize();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('saves and reloads boards, including nested item details', () async {
    final board = RankBoard(
      id: 'b1',
      title: 'Chicken Burgers',
      emoji: '🍔',
      items: [
        RankItem(
          id: 'i1',
          name: 'Five Guys',
          brand: 'Five Guys',
          itemName: 'Cheeseburger',
          price: '13.99',
          tier: 'S',
          pros: ['Juicy', 'Fresh buns'],
          cons: ['Pricey'],
          location: 'Downtown',
        ),
      ],
    );

    await StorageService.instance.saveBoards([board]);
    final loaded = StorageService.instance.loadBoards();

    expect(loaded, hasLength(1));
    expect(loaded.first.title, 'Chicken Burgers');
    expect(loaded.first.items.single.tier, 'S');
    expect(loaded.first.items.single.pros, ['Juicy', 'Fresh buns']);
    expect(loaded.first.items.single.location, 'Downtown');
    expect(loaded.first.items.single.brand, 'Five Guys');
    expect(loaded.first.items.single.itemName, 'Cheeseburger');
    expect(loaded.first.items.single.price, '13.99');
  });

  test('loadBoards returns an empty list when nothing has been saved', () {
    expect(StorageService.instance.loadBoards(), isEmpty);
  });

  test(
    'keepImage copies the source file into the app documents directory',
    () async {
      final source = File('${tempDir.path}/source.jpg')
        ..writeAsBytesSync([1, 2, 3]);

      final savedPath = await StorageService.instance.keepImage(
        source.path,
        'item-1',
      );

      expect(File(savedPath).existsSync(), isTrue);
      expect(savedPath, contains('rank_it_item-1'));
    },
  );
}
