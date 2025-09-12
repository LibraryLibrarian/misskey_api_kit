import 'package:misskey_api_core/misskey_api_core.dart' as core;

/// 通知関連の高レベルAPIエントリ
///
/// - 役割: Notifications系エンドポイントをSDK視点で提供
/// - 実処理: 下層の `MisskeyHttpClient` に委譲
class NotificationsApi {
  final core.MisskeyHttpClient http;

  /// コンストラクタ
  const NotificationsApi({required this.http});
}
