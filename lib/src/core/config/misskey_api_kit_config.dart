import 'package:misskey_api_core/misskey_api_core.dart' as core;

/// Misskey API Kit の設定
///
/// - 役割: 下層の `misskey_api_core` の `MisskeyApiConfig` を保持し、Kit側で必要となる付加設定を集約
/// - 想定利用: `MisskeyApiKitClient` の構築時に渡す
class MisskeyApiKitConfig {
  /// 下層トランスポート層の設定
  final core.MisskeyApiConfig coreConfig;

  /// SDKレベルのデバッグログを有効化するか
  final bool enableSdkLog;

  /// コンストラクタ
  ///
  /// - [coreConfig]: Misskey API 呼び出しの基本設定
  /// - [enableSdkLog]: SDKレベルのログ出力切り替え
  const MisskeyApiKitConfig({required this.coreConfig, this.enableSdkLog = false});
}
