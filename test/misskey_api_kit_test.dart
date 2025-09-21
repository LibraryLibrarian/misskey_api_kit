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
  });
}
