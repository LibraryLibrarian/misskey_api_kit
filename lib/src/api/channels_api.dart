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
      throw mapAnyToKitException(e, endpoint: '/channels/my-favorites');
    }
  }

  /// 指定チャンネルのタイムラインを取得する（/api/channels/timeline）
  ///
  /// - パラメータ: [channelId] 必須、[limit] 取得上限、[sinceId]/[untilId] ページング用
  /// - 備考: レスポンス要素に `{ note: {...} }` が混在する実装があるため、
  ///   本メソッドは生配列のJSONを返す。呼び出し側で `note` の有無に応じて解釈する
  /// - 認証: 必須
  /// - リトライ: 読み取り系のため `idempotent=true`
  Future<List<Map<String, dynamic>>> timeline({
    required String channelId,
    int limit = 30,
    String? sinceId,
    String? untilId,
  }) async {
    try {
      final Map<String, dynamic> body = <String, dynamic>{
        'channelId': channelId,
        'limit': limit,
        if (sinceId != null) 'sinceId': sinceId,
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
      throw mapAnyToKitException(e, endpoint: '/channels/timeline');
    }
  }

  /// 注目のチャンネル一覧を取得する（/api/channels/featured）
  ///
  /// - 認証: 任意（トークンなしでも取得可能な実装が多い）
  /// - リトライ: 読み取り系のため `idempotent=true`
  Future<List<Map<String, dynamic>>> featured({int limit = 30}) async {
    try {
      final List<dynamic> res = await http.send<List<dynamic>>(
        '/channels/featured',
        method: 'POST',
        body: <String, dynamic>{'limit': limit},
        options: const core.RequestOptions(authRequired: false, idempotent: true),
      );
      return res.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    } catch (e) {
      throw mapAnyToKitException(e, endpoint: '/channels/featured');
    }
  }

  /// フォロー中のチャンネル一覧を取得する（/api/channels/followed）
  ///
  /// - 認証: 必須
  /// - リトライ: 読み取り系のため `idempotent=true`
  Future<List<Map<String, dynamic>>> followed({int limit = 100}) async {
    try {
      final List<dynamic> res = await http.send<List<dynamic>>(
        '/channels/followed',
        method: 'POST',
        body: <String, dynamic>{'limit': limit},
        options: const core.RequestOptions(authRequired: true, idempotent: true),
      );
      return res.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    } catch (e) {
      throw mapAnyToKitException(e, endpoint: '/channels/followed');
    }
  }

  /// 自分が所有するチャンネル一覧を取得する（/api/channels/owned）
  ///
  /// - 認証: 必須
  /// - リトライ: 読み取り系のため `idempotent=true`
  Future<List<Map<String, dynamic>>> owned({int limit = 100}) async {
    try {
      final List<dynamic> res = await http.send<List<dynamic>>(
        '/channels/owned',
        method: 'POST',
        body: <String, dynamic>{'limit': limit},
        options: const core.RequestOptions(authRequired: true, idempotent: true),
      );
      return res.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    } catch (e) {
      throw mapAnyToKitException(e, endpoint: '/channels/owned');
    }
  }

  /// チャンネル詳細を取得する（/api/channels/show）
  ///
  /// - 認証: 任意（公開情報の取得）
  /// - 返り値: チャンネルのJSON
  Future<Map<String, dynamic>> show({required String channelId}) async {
    try {
      final Map res = await http.send<Map>(
        '/channels/show',
        method: 'POST',
        body: <String, dynamic>{'channelId': channelId},
        options: const core.RequestOptions(authRequired: false, idempotent: true),
      );
      return res.cast<String, dynamic>();
    } catch (e) {
      throw mapAnyToKitException(e, endpoint: '/channels/show');
    }
  }

  /// チャンネルを検索する（/api/channels/search）
  ///
  /// - パラメータ: [query] 検索語、[limit] 取得上限
  /// - 認証: 任意
  Future<List<Map<String, dynamic>>> search({required String query, int limit = 30}) async {
    try {
      final List<dynamic> res = await http.send<List<dynamic>>(
        '/channels/search',
        method: 'POST',
        body: <String, dynamic>{'query': query, 'limit': limit},
        options: const core.RequestOptions(authRequired: false, idempotent: true),
      );
      return res.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    } catch (e) {
      throw mapAnyToKitException(e, endpoint: '/channels/search');
    }
  }

  /// チャンネルをお気に入り登録する（/api/channels/favorite）
  ///
  /// - 認証: 必須
  Future<void> favorite({required String channelId}) async {
    try {
      await http.send<Map>(
        '/channels/favorite',
        method: 'POST',
        body: <String, dynamic>{'channelId': channelId},
        options: const core.RequestOptions(authRequired: true),
      );
    } catch (e) {
      throw mapAnyToKitException(e, endpoint: '/channels/favorite');
    }
  }

  /// チャンネルのお気に入りを解除する（/api/channels/unfavorite）
  ///
  /// - 認証: 必須
  Future<void> unfavorite({required String channelId}) async {
    try {
      await http.send<Map>(
        '/channels/unfavorite',
        method: 'POST',
        body: <String, dynamic>{'channelId': channelId},
        options: const core.RequestOptions(authRequired: true),
      );
    } catch (e) {
      throw mapAnyToKitException(e, endpoint: '/channels/unfavorite');
    }
  }

  /// チャンネルをフォローする（/api/channels/follow）
  ///
  /// - 認証: 必須
  Future<void> follow({required String channelId}) async {
    try {
      await http.send<Map>(
        '/channels/follow',
        method: 'POST',
        body: <String, dynamic>{'channelId': channelId},
        options: const core.RequestOptions(authRequired: true),
      );
    } catch (e) {
      throw mapAnyToKitException(e, endpoint: '/channels/follow');
    }
  }

  /// チャンネルのフォローを解除する（/api/channels/unfollow）
  ///
  /// - 認証: 必須
  Future<void> unfollow({required String channelId}) async {
    try {
      await http.send<Map>(
        '/channels/unfollow',
        method: 'POST',
        body: <String, dynamic>{'channelId': channelId},
        options: const core.RequestOptions(authRequired: true),
      );
    } catch (e) {
      throw mapAnyToKitException(e, endpoint: '/channels/unfollow');
    }
  }
}
