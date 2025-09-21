import 'package:misskey_api_core/misskey_api_core.dart' as core;

import '../core/error/misskey_api_kit_exception.dart';

/// ユーザーのJSON表現
typedef UserJson = Map<String, dynamic>;

/// 関係オブジェクトのJSON表現
typedef RelationJson = Map<String, dynamic>;

/// ユーザーのノート取得で返却するノートJSON表現
typedef UserNoteJson = Map<String, dynamic>;

/// Users系の高レベルAPIエントリ
///
/// - 役割: Users系エンドポイント（show/search/followers/following/relation/recommendation/notes）を
///   SDK視点で扱いやすい形で提供する
/// - 実処理: 下層の `MisskeyHttpClient` に委譲し、例外は `MisskeyApiKitException` に正規化して投げ直す
class UsersApi {
  final core.MisskeyHttpClient http;

  /// コンストラクタ
  const UsersApi({required this.http});

  /// ユーザー情報を1件取得（`/api/users/show`）
  ///
  /// - 処理内容: `userId` または `username`（必要に応じて `host`）で単一ユーザー詳細を取得する
  /// - 入力: `userId` と `username` はいずれか一方を指定（両方は不可）
  /// - 認証: 原則必須（アクセストークン）
  /// - ページング: なし
  /// - 例外: 失敗時は `MisskeyApiKitException` に正規化
  Future<UserJson> showOne({String? userId, String? username, String? host}) async {
    try {
      final Map<String, dynamic> body = <String, dynamic>{
        if (userId != null) 'userId': userId,
        if (username != null) 'username': username,
        if (host != null && host.isNotEmpty) 'host': host,
      };

      final Map res = await http.send<Map>(
        '/users/show',
        method: 'POST',
        body: body,
        options: const core.RequestOptions(authRequired: true, idempotent: true),
      );
      return res.cast<String, dynamic>();
    } catch (e) {
      throw mapAnyToKitException(e, endpoint: '/users/show');
    }
  }

  /// ユーザー情報を複数件まとめて取得（`/api/users/show`）
  ///
  /// - 処理内容: `userIds` を配列で渡すと、複数ユーザー詳細の配列が返るMisskeyの分岐仕様に合わせる
  /// - 入力: `userIds` は1件以上
  /// - 認証: 原則必須（アクセストークン）
  /// - ページング: なし
  /// - 例外: 失敗時は `MisskeyApiKitException` に正規化
  Future<List<UserJson>> showMany({required List<String> userIds}) async {
    try {
      final Map<String, dynamic> body = <String, dynamic>{'userIds': userIds};
      final List<dynamic> res = await http.send<List<dynamic>>(
        '/users/show',
        method: 'POST',
        body: body,
        options: const core.RequestOptions(authRequired: true, idempotent: true),
      );
      return res.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    } catch (e) {
      throw mapAnyToKitException(e, endpoint: '/users/show');
    }
  }

  /// ユーザー検索（`/api/users/search`）
  ///
  /// - 処理内容: クエリ文字列でユーザーを検索する
  /// - 入力: `query` は必須
  /// - ページング: `limit` / `offset`
  /// - 例外: 失敗時は `MisskeyApiKitException` に正規化
  Future<List<UserJson>> search({
    required String query,
    int limit = 30,
    int? offset,
    String? host,
    bool? detail,
  }) async {
    try {
      final Map<String, dynamic> body = <String, dynamic>{
        'query': query,
        'limit': limit,
        if (offset != null) 'offset': offset,
        if (host != null && host.isNotEmpty) 'host': host,
        if (detail != null) 'detail': detail,
      };
      final List<dynamic> res = await http.send<List<dynamic>>(
        '/users/search',
        method: 'POST',
        body: body,
        options: const core.RequestOptions(authRequired: true, idempotent: true),
      );
      return res.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    } catch (e) {
      throw mapAnyToKitException(e, endpoint: '/users/search');
    }
  }

  /// フォロワー一覧を取得（`/api/users/followers`）
  ///
  /// - 処理内容: 対象ユーザーのフォロワーを取得する
  /// - 入力: `userId` または `username`（必要に応じて `host`）
  /// - ページング: `limit` / `sinceId` / `untilId`
  /// - 例外: 失敗時は `MisskeyApiKitException` に正規化
  Future<List<UserJson>> followers({
    String? userId,
    String? username,
    String? host,
    int limit = 30,
    String? sinceId,
    String? untilId,
  }) async {
    try {
      final Map<String, dynamic> body = <String, dynamic>{
        'limit': limit,
        if (userId != null) 'userId': userId,
        if (username != null) 'username': username,
        if (host != null && host.isNotEmpty) 'host': host,
        if (sinceId != null) 'sinceId': sinceId,
        if (untilId != null) 'untilId': untilId,
      };
      final List<dynamic> res = await http.send<List<dynamic>>(
        '/users/followers',
        method: 'POST',
        body: body,
        options: const core.RequestOptions(authRequired: true, idempotent: true),
      );
      return res.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    } catch (e) {
      throw mapAnyToKitException(e, endpoint: '/users/followers');
    }
  }

  /// フォロー一覧を取得（`/api/users/following`）
  ///
  /// - 処理内容: 対象ユーザーがフォローしているユーザーを取得する
  /// - 入力: `userId` または `username`（必要に応じて `host`）
  /// - ページング: `limit` / `sinceId` / `untilId`
  /// - 例外: 失敗時は `MisskeyApiKitException` に正規化
  Future<List<UserJson>> following({
    String? userId,
    String? username,
    String? host,
    int limit = 30,
    String? sinceId,
    String? untilId,
  }) async {
    try {
      final Map<String, dynamic> body = <String, dynamic>{
        'limit': limit,
        if (userId != null) 'userId': userId,
        if (username != null) 'username': username,
        if (host != null && host.isNotEmpty) 'host': host,
        if (sinceId != null) 'sinceId': sinceId,
        if (untilId != null) 'untilId': untilId,
      };
      final List<dynamic> res = await http.send<List<dynamic>>(
        '/users/following',
        method: 'POST',
        body: body,
        options: const core.RequestOptions(authRequired: true, idempotent: true),
      );
      return res.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    } catch (e) {
      throw mapAnyToKitException(e, endpoint: '/users/following');
    }
  }

  /// 対象ユーザーとの関係を取得（`/api/users/relation`）
  ///
  /// - 処理内容: 指定したユーザーID配列に対する関係フラグ（フォロー/フォロワー/ミュート/ブロック 等）を取得する
  /// - 入力: `userIds` は1件以上
  /// - 認証: 必須（アクセストークン）
  /// - ページング: なし
  /// - 例外: 失敗時は `MisskeyApiKitException` に正規化
  Future<List<RelationJson>> relation({required List<String> userIds}) async {
    try {
      final Map<String, dynamic> body = <String, dynamic>{'userIds': userIds};
      final List<dynamic> res = await http.send<List<dynamic>>(
        '/users/relation',
        method: 'POST',
        body: body,
        options: const core.RequestOptions(authRequired: true, idempotent: true),
      );
      return res.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    } catch (e) {
      throw mapAnyToKitException(e, endpoint: '/users/relation');
    }
  }

  /// おすすめユーザーを取得（`/api/users/recommendation`）
  ///
  /// - 処理内容: サーバが算出したユーザー推薦を取得して返す
  /// - 入力: `limit` は取得件数（サーバ側上限あり）
  /// - 認証: 必須（アクセストークン）
  /// - ページング: `limit`
  /// - 例外: 失敗時は `MisskeyApiKitException` に正規化
  Future<List<UserJson>> recommendation({int limit = 30}) async {
    try {
      final Map<String, dynamic> body = <String, dynamic>{'limit': limit};
      final List<dynamic> res = await http.send<List<dynamic>>(
        '/users/recommendation',
        method: 'POST',
        body: body,
        options: const core.RequestOptions(authRequired: true, idempotent: true),
      );
      return res.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    } catch (e) {
      throw mapAnyToKitException(e, endpoint: '/users/recommendation');
    }
  }

  /// 指定ユーザーのノート一覧を取得（`/api/users/notes`）
  ///
  /// - 処理内容: 対象ユーザーのノート（投稿）を取得する
  /// - 入力: `userId` または `username`（必要に応じて `host`）
  /// - ページング: `limit` / `sinceId` / `untilId`
  /// - オプション: `includeReplies` / `includeRenotes`
  /// - 例外: 失敗時は `MisskeyApiKitException` に正規化
  Future<List<UserNoteJson>> notes({
    String? userId,
    String? username,
    String? host,
    int limit = 30,
    String? sinceId,
    String? untilId,
    bool? includeReplies,
    bool? includeRenotes,
  }) async {
    try {
      final Map<String, dynamic> body = <String, dynamic>{
        'limit': limit,
        if (userId != null) 'userId': userId,
        if (username != null) 'username': username,
        if (host != null && host.isNotEmpty) 'host': host,
        if (sinceId != null) 'sinceId': sinceId,
        if (untilId != null) 'untilId': untilId,
        if (includeReplies != null) 'includeReplies': includeReplies,
        if (includeRenotes != null) 'includeRenotes': includeRenotes,
      };
      final List<dynamic> res = await http.send<List<dynamic>>(
        '/users/notes',
        method: 'POST',
        body: body,
        options: const core.RequestOptions(authRequired: true, idempotent: true),
      );
      return res.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    } catch (e) {
      throw mapAnyToKitException(e, endpoint: '/users/notes');
    }
  }
}
