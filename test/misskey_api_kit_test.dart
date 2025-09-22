import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_api_core/misskey_api_core.dart' as core;
import 'package:misskey_api_kit/misskey_api_kit.dart';

void main() {
  test('クライアントの初期化が成功する', () {
    final config = core.MisskeyApiConfig(baseUrl: Uri.parse('https://example.com'));
    final kitConfig = MisskeyApiKitConfig(coreConfig: config);
    final client = MisskeyApiKitClient(config: kitConfig);
    expect(client.notes, isNotNull);
    expect(client.notifications, isNotNull);
    expect(client.channels, isNotNull);
    expect(client.users, isNotNull);
    expect(client.account, isNotNull);
  });

  test('NotesApi の主要メソッドが存在する', () {
    final config = core.MisskeyApiConfig(baseUrl: Uri.parse('https://example.com'));
    final kitConfig = MisskeyApiKitConfig(coreConfig: config);
    final client = MisskeyApiKitClient(config: kitConfig);

    // ネットワークは呼ばず、メソッドのティアオフで存在性のみ検証
    expect(client.notes.show, isA<Function>());
    expect(client.notes.delete, isA<Function>());
    expect(client.notes.reactions, isA<Function>());
    expect(client.notes.reactionsCreate, isA<Function>());
    expect(client.notes.reactionsDelete, isA<Function>());
    expect(client.notes.favoritesCreate, isA<Function>());
    expect(client.notes.favoritesDelete, isA<Function>());
    expect(client.notes.search, isA<Function>());
    expect(client.notes.searchByTag, isA<Function>());
    expect(client.notes.replies, isA<Function>());
    expect(client.notes.renotes, isA<Function>());
  });

  test('AccountApi の i() が存在する', () {
    final config = core.MisskeyApiConfig(baseUrl: Uri.parse('https://example.com'));
    final kitConfig = MisskeyApiKitConfig(coreConfig: config);
    final client = MisskeyApiKitClient(config: kitConfig);
    expect(client.account.i, isA<Function>());
  });
}
