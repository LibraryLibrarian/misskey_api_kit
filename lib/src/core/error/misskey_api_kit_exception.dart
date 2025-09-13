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

/// 例外マッピングの共通関数
///
/// - 目的: アプリ側が dio に依存せず HTTP ステータス（401/403/429 等）を判定可能にする
MisskeyApiKitException mapAnyToKitException(Object error, {String? endpoint}) {
  // misskey_api_core の MisskeyApiException を優先的に移送
  try {
    // ignore: avoid_dynamic_calls
    final isCore = error.runtimeType.toString().contains('MisskeyApiException');
    if (isCore) {
      // ignore: avoid_dynamic_calls
      final int? status = (error as dynamic).statusCode as int?;
      // ignore: avoid_dynamic_calls
      final String message = (error as dynamic).message as String? ?? 'API error';
      // ignore: avoid_dynamic_calls
      final String? code = (error as dynamic).code as String?;
      return MisskeyApiKitException(statusCode: status, code: code, message: message, endpoint: endpoint, raw: error);
    }
  } catch (_) {}

  // DioException から statusCode / data を抽出
  try {
    final isDio = error.runtimeType.toString().contains('DioException');
    if (isDio) {
      // ignore: avoid_dynamic_calls
      final response = (error as dynamic).response;
      final int? status = response?.statusCode as int?;
      final Object? body = response?.data;
      // ignore: avoid_dynamic_calls
      final String message = (error as dynamic).message as String? ?? 'HTTP error';
      return MisskeyApiKitException(
        statusCode: status,
        message: message,
        endpoint: endpoint,
        responseBody: body,
        raw: error,
      );
    }
  } catch (_) {}

  // フォールバック
  return MisskeyApiKitException(message: 'Unexpected error', endpoint: endpoint, raw: error);
}
