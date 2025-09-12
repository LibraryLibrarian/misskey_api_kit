import 'package:misskey_api_core/misskey_api_core.dart' as core;

/// ノート関連の高レベルAPIエントリ
///
/// - 役割: Notes系エンドポイントをSDK視点で提供
/// - 実処理: 下層の `MisskeyHttpClient` に委譲
class NotesApi {
  final core.MisskeyHttpClient http;

  /// コンストラクタ
  const NotesApi({required this.http});
}
