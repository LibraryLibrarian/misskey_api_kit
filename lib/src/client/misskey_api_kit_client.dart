import 'package:misskey_api_core/misskey_api_core.dart' as core;

import '../api/notes_api.dart';
import '../api/notifications_api.dart';
import '../core/config/misskey_api_kit_config.dart';

/// Misskey API Kit のクライアント
///
/// - 役割: `misskey_api_core` のHTTPクライアントを内部で保持し、
///   ドメイン別API（Notes/Notifications など）へのエントリーポイントを提供する
/// - 利用方法: 構築時に `MisskeyApiKitConfig` とトークン供給関数を渡し、各APIを通じてMisskeyのRESTエンドポイントを呼び出す
class MisskeyApiKitClient {
  /// 下層のHTTPクライアント
  final core.MisskeyHttpClient http;

  /// ノート関連API
  final NotesApi notes;

  /// 通知関連API
  final NotificationsApi notifications;

  /// コンストラクタ
  ///
  /// - [config]: Kit設定（下層の `MisskeyApiConfig` を含む）
  /// - [tokenProvider]: 認可トークン供給関数
  /// - [logger]: ロガー（省略時は `misskey_api_core` の既定ロガー）
  MisskeyApiKitClient({required MisskeyApiKitConfig config, core.TokenProvider? tokenProvider, core.Logger? logger})
    : http = core.MisskeyHttpClient(config: config.coreConfig, tokenProvider: tokenProvider, logger: logger),
      notes = NotesApi(
        http: core.MisskeyHttpClient(config: config.coreConfig, tokenProvider: tokenProvider, logger: logger),
      ),
      notifications = NotificationsApi(
        http: core.MisskeyHttpClient(config: config.coreConfig, tokenProvider: tokenProvider, logger: logger),
      );
}
