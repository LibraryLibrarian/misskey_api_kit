import 'package:misskey_api_core/misskey_api_core.dart' as core;

import '../core/error/misskey_api_kit_exception.dart';

/// チャンネル関連の高レベルAPIエントリ
///
/// - 役割: Channels系エンドポイントをSDK視点で提供
/// - 実処理: 下層の `MisskeyHttpClient` に委譲
class ChannelsApi {
  final core.MisskeyHttpClient http;

  /// コンストラクタ
  const ChannelsApi({required this.http});

  /// お気に入り登録済みのチャンネル一覧を取得する（/api/channels/my-favorites）
  ///
  /// - パラメータ: [limit] 取得上限（既定100）
  /// - 認証: 必須
  /// - リトライ: 読み取り系のため `idempotent=true`
  Future<List<Map<String, dynamic>>> myFavorites({int limit = 100}) async {
    try {
      final List<dynamic> res = await http.send<List<dynamic>>(
        '/channels/my-favorites',
        method: 'POST',
        body: <String, dynamic>{'limit': limit},
        options: const core.RequestOptions(authRequired: true, idempotent: true),
      );
      return res.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    } catch (e) {
      throw _mapException(e, endpoint: '/channels/my-favorites');
    }
  }

  /// 指定チャンネルのタイムラインを取得する（/api/channels/timeline）
  ///
  /// - パラメータ: [channelId] 必須、[limit] 取得上限、[untilId] ページング用
  /// - 備考: レスポンス要素に `{ note: {...} }` が混在する実装があるため、
  ///   本メソッドは生配列のJSONを返す。呼び出し側で `note` の有無に応じて解釈する
  /// - 認証: 必須
  /// - リトライ: 読み取り系のため `idempotent=true`
  Future<List<Map<String, dynamic>>> timeline({required String channelId, int limit = 30, String? untilId}) async {
    try {
      final Map<String, dynamic> body = <String, dynamic>{
        'channelId': channelId,
        'limit': limit,
        if (untilId != null) 'untilId': untilId,
      };
      final List<dynamic> res = await http.send<List<dynamic>>(
        '/channels/timeline',
        method: 'POST',
        body: body,
        options: const core.RequestOptions(authRequired: true, idempotent: true),
      );
      return res.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    } catch (e) {
      throw _mapException(e, endpoint: '/channels/timeline');
    }
  }

  MisskeyApiKitException _mapException(Object e, {required String endpoint}) {
    if (e is core.MisskeyApiException) {
      return MisskeyApiKitException(
        statusCode: e.statusCode,
        code: e.code,
        message: e.message,
        endpoint: endpoint,
        raw: e,
      );
    }
    return MisskeyApiKitException(message: 'Unexpected error', endpoint: endpoint, raw: e);
  }
}
