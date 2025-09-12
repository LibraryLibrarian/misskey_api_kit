/// Misskey API Kit の共通例外
///
/// - 目的: 下層のHTTP例外やMisskey固有エラーをSDK視点で集約し、アプリ側が一貫した例外ハンドリングを行えるようにする
/// - 主なフィールド:
///   - [statusCode]: HTTPステータスコード
///   - [code]: Misskey固有のエラーコード等
///   - [message]: 人間が読めるメッセージ
///   - [endpoint]: 失敗したエンドポイント（任意）
///   - [requestId]: サーバが返す相関ID等（任意）
///   - [retryAfter]: レート制限時の再試行秒数（任意）
///   - [responseBody]: レスポンス本文の一部（任意）
class MisskeyApiKitException implements Exception {
  final int? statusCode;
  final String? code;
  final String message;
  final String? endpoint;
  final String? requestId;
  final int? retryAfter;
  final Object? responseBody;
  final Object? raw;

  /// コンストラクタ
  const MisskeyApiKitException({
    this.statusCode,
    this.code,
    required this.message,
    this.endpoint,
    this.requestId,
    this.retryAfter,
    this.responseBody,
    this.raw,
  });

  @override
  String toString() =>
      'MisskeyApiKitException(statusCode: '
      '$statusCode, code: $code, message: $message, endpoint: $endpoint)';
}
