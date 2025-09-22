import 'package:misskey_api_core/misskey_api_core.dart' as core;

import '../core/error/misskey_api_kit_exception.dart';

/// 現在ログイン中ユーザー（自分）のAPI
///
/// - 役割: `/api/i` を呼び出し、認証済みユーザーの詳細を取得する
/// - 実処理: 下層の `MisskeyHttpClient` に委譲し、例外は `MisskeyApiKitException` に正規化して投げ直す
class AccountApi {
  /// 下層のHTTPクライアント
  final core.MisskeyHttpClient http;

  /// コンストラクタ
  const AccountApi({required this.http});

  /// 現在ログイン中ユーザー詳細を取得（`/api/i`）
  ///
  /// - 処理内容: 認証トークンに紐づくユーザー（自分）の詳細情報（MeDetailed）を取得する
  /// - 入力: なし（ボディ不要）
  /// - 認証: 必須（アクセストークン）
  /// - ページング: なし
  /// - 例外: 失敗時は `MisskeyApiKitException` に正規化
  Future<Map<String, dynamic>> i() async {
    try {
      // Misskey は POST 時に Content-Type: application/json を期待するため、
      // 空ボディであっても空の JSON オブジェクトを送る。
      final Map res = await http.send<Map>(
        '/i',
        method: 'POST',
        body: const <String, dynamic>{},
        options: const core.RequestOptions(authRequired: true, idempotent: true),
      );
      return res.cast<String, dynamic>();
    } catch (e) {
      throw mapAnyToKitException(e, endpoint: '/i');
    }
  }
}
