import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:rank_it/main.dart';
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
    tempDir = await Directory.systemTemp.createTemp('rank_it_widget_test');
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

  testWidgets('shows the empty state with no boards yet', (WidgetTester tester) async {
    // HomeScreen reads already-open Hive data synchronously in initState,
    // so a single pump is enough — no real async gap to wait out here.
    // (Deliberately not using tester.runAsync: doing so would give the
    // BannerAd's real platform-channel call in ads_service.dart enough real
    // time to reject with MissingPluginException in this plugin-less test
    // environment, same as it would if we awaited it directly.)
    await tester.pumpWidget(const RankItApp());
    await tester.pump();

    expect(find.text('RANK IT'), findsOneWidget);
    expect(find.text('Create your first ranking'), findsOneWidget);
  });
}
