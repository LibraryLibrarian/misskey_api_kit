import 'package:misskey_api_core/misskey_api_core.dart' as core;

import '../core/error/misskey_api_kit_exception.dart';

/// NoteのJSON表現（最初はMapとして返す）
typedef NoteJson = Map<String, dynamic>;

/// ノート関連の高レベルAPIエントリ
///
/// - 役割: Notes系エンドポイントをSDK視点で提供
/// - 実処理: 下層の `MisskeyHttpClient` に委譲
class NotesApi {
  final core.MisskeyHttpClient http;

  /// コンストラクタ
  const NotesApi({required this.http});

  /// ノートを作成（通常投稿/引用/純リノートを兼用）
  ///
  /// - 処理内容: `/api/notes/create` を呼び出し、レスポンスが `{ createdNote: {...} }` の場合でも
  ///   ノート本体のJSONに正規化して返す
  ///
  /// - 重要: `channelId` を指定するチャンネル投稿時は、可視性関連のクライアント指定は
  ///   サーバ実装側で無視（上書き・破棄）される。そのため本メソッドでは、
  ///   `channelId != null` の場合に `visibility`/`localOnly`/`visibleUserIds` を送信しない。
  ///
  ///   送信しない理由:
  ///   チャンネル投稿はチャンネルのポリシーに従って公開範囲等が決まるため、
  ///   個別ノートの可視性指定や指定ユーザー宛（specified）は適用されない。
  ///   Misskey backend `notes/create` では、`channelId` がある場合に
  ///   `visibility` や `visibleUserIds`、`localOnly` を実質無効化（固定）する分岐がある。
  ///   実装参照:
  ///   - GitHub: packages/backend/src/server/api/endpoints/notes/create.ts（develop）
  ///     https://github.com/misskey-dev/misskey/blob/develop/packages/backend/src/server/api/endpoints/notes/create.ts
  ///
  /// - 送信パラメータの整理:
  ///   - `channelId` あり: `text`/`renoteId`/`channelId` 等のみ送信
  ///     `visibility`/`localOnly`/`visibleUserIds` は送らない（送ってもサーバで無視されるため）
  ///   - `channelId` なし: `visibility`/`localOnly`/`visibleUserIds` を必要に応じて送信可能
  ///
  /// - 投票の送信:
  ///   - `pollChoices` を指定した場合に `poll` オブジェクトを組み立てて送信（`choices` は必須）
  ///   - `pollMultiple` が `true` の場合のみ `multiple: true` を付与
  ///   - `pollExpiresAtEpochMs` が指定されていれば `expiresAt`（UTCエポックms）を付与
  Future<NoteJson> create({
    String? text,
    String? visibility,
    bool localOnly = false,
    List<String>? visibleUserIds,
    String? channelId,
    String? renoteId,
    // 投票（任意）
    List<String>? pollChoices,
    bool? pollMultiple,
    int? pollExpiresAtEpochMs,
  }) async {
    try {
      final Map<String, dynamic> body = <String, dynamic>{
        if (text != null) 'text': text,
        if (channelId != null) 'channelId': channelId,
        if (renoteId != null) 'renoteId': renoteId,
      };

      if (channelId == null) {
        if (visibility != null) body['visibility'] = visibility;
        if (localOnly) body['localOnly'] = true;
        if (visibleUserIds != null && visibleUserIds.isNotEmpty) {
          body['visibleUserIds'] = visibleUserIds;
        }
      }

      // 投票オブジェクトの付与（choices がある場合のみ）
      if (pollChoices != null && pollChoices.isNotEmpty) {
        final Map<String, dynamic> poll = <String, dynamic>{'choices': pollChoices};
        if (pollMultiple == true) poll['multiple'] = true;
        if (pollExpiresAtEpochMs != null) poll['expiresAt'] = pollExpiresAtEpochMs;
        body['poll'] = poll;
      }

      final Map res = await http.send<Map>(
        '/notes/create',
        method: 'POST',
        body: body,
        options: const core.RequestOptions(authRequired: true),
      );

      final Map rawNote = (res['createdNote'] is Map) ? (res['createdNote'] as Map) : res;
      return rawNote.cast<String, dynamic>();
    } catch (e) {
      throw mapAnyToKitException(e, endpoint: '/notes/create');
    }
  }

  /// ノートを取得（`/api/notes/show`）
  ///
  /// - 処理内容: 指定した `noteId` のノート詳細を取得して返す
  /// - 認証: 必須（アクセストークン）
  /// - 例外: 失敗時は `MisskeyApiKitException` に正規化
  Future<NoteJson> show({required String noteId}) async {
    try {
      final Map res = await http.send<Map>(
        '/notes/show',
        method: 'POST',
        body: <String, dynamic>{'noteId': noteId},
        options: const core.RequestOptions(authRequired: true, idempotent: true),
      );
      return res.cast<String, dynamic>();
    } catch (e) {
      throw mapAnyToKitException(e, endpoint: '/notes/show');
    }
  }

  /// ノートを削除（`/api/notes/delete`）
  ///
  /// - 処理内容: 自分のノートを削除する
  /// - 認証: 必須（アクセストークン）
  /// - 例外: 失敗時は `MisskeyApiKitException` に正規化
  Future<void> delete({required String noteId}) async {
    try {
      await http.send<Map>(
        '/notes/delete',
        method: 'POST',
        body: <String, dynamic>{'noteId': noteId},
        options: const core.RequestOptions(authRequired: true),
      );
    } catch (e) {
      throw mapAnyToKitException(e, endpoint: '/notes/delete');
    }
  }

  /// ノートのリアクション一覧を取得（`/api/notes/reactions`）
  ///
  /// - 処理内容: 指定ノートに付与されたリアクションの一覧を取得する
  /// - ページング: `limit`/`sinceId`/`untilId`
  /// - 認証: 必須（アクセストークン）
  /// - 例外: 失敗時は `MisskeyApiKitException` に正規化
  Future<List<Map<String, dynamic>>> reactions({
    required String noteId,
    int limit = 30,
    String? sinceId,
    String? untilId,
  }) async {
    try {
      final Map<String, dynamic> body = <String, dynamic>{
        'noteId': noteId,
        'limit': limit,
        if (sinceId != null) 'sinceId': sinceId,
        if (untilId != null) 'untilId': untilId,
      };
      final List<dynamic> res = await http.send<List<dynamic>>(
        '/notes/reactions',
        method: 'POST',
        body: body,
        options: const core.RequestOptions(authRequired: true, idempotent: true),
      );
      return res.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    } catch (e) {
      throw mapAnyToKitException(e, endpoint: '/notes/reactions');
    }
  }

  /// ノートにリアクションを付与（`/api/notes/reactions/create`）
  ///
  /// - 処理内容: 指定ノートに `reaction`（Unicode または :shortcode:）を付与する
  /// - 認証: 必須（アクセストークン）
  /// - 例外: 失敗時は `MisskeyApiKitException` に正規化
  Future<void> reactionsCreate({required String noteId, required String reaction}) async {
    try {
      await http.send<Map>(
        '/notes/reactions/create',
        method: 'POST',
        body: <String, dynamic>{'noteId': noteId, 'reaction': reaction},
        options: const core.RequestOptions(authRequired: true),
      );
    } catch (e) {
      throw mapAnyToKitException(e, endpoint: '/notes/reactions/create');
    }
  }

  /// ノートの自分のリアクションを解除（`/api/notes/reactions/delete`）
  ///
  /// - 処理内容: 自分が付与したリアクションを取り消す（冪等）
  /// - 認証: 必須（アクセストークン）
  /// - 例外: 失敗時は `MisskeyApiKitException` に正規化
  Future<void> reactionsDelete({required String noteId}) async {
    try {
      await http.send<Map>(
        '/notes/reactions/delete',
        method: 'POST',
        body: <String, dynamic>{'noteId': noteId},
        options: const core.RequestOptions(authRequired: true),
      );
    } catch (e) {
      throw mapAnyToKitException(e, endpoint: '/notes/reactions/delete');
    }
  }

  /// ノートをお気に入りに追加（`/api/notes/favorites/create`）
  ///
  /// - 処理内容: 指定ノートを自分のお気に入りに登録する
  /// - 認証: 必須（アクセストークン）
  /// - 例外: 失敗時は `MisskeyApiKitException` に正規化
  Future<void> favoritesCreate({required String noteId}) async {
    try {
      await http.send<Map>(
        '/notes/favorites/create',
        method: 'POST',
        body: <String, dynamic>{'noteId': noteId},
        options: const core.RequestOptions(authRequired: true),
      );
    } catch (e) {
      throw mapAnyToKitException(e, endpoint: '/notes/favorites/create');
    }
  }

  /// ノートをお気に入りから削除（`/api/notes/favorites/delete`）
  ///
  /// - 処理内容: 指定ノートを自分のお気に入りから外す（冪等）
  /// - 認証: 必須（アクセストークン）
  /// - 例外: 失敗時は `MisskeyApiKitException` に正規化
  Future<void> favoritesDelete({required String noteId}) async {
    try {
      await http.send<Map>(
        '/notes/favorites/delete',
        method: 'POST',
        body: <String, dynamic>{'noteId': noteId},
        options: const core.RequestOptions(authRequired: true),
      );
    } catch (e) {
      throw mapAnyToKitException(e, endpoint: '/notes/favorites/delete');
    }
  }

  /// ノート検索（`/api/notes/search`）
  ///
  /// - 処理内容: クエリ文字列に一致するノートを検索する
  /// - ページング: `limit`/`sinceId`/`untilId`
  /// - 認証: 必須（アクセストークン）
  /// - 例外: 失敗時は `MisskeyApiKitException` に正規化
  Future<List<NoteJson>> search({required String query, int limit = 30, String? sinceId, String? untilId}) async {
    try {
      final Map<String, dynamic> body = <String, dynamic>{
        'query': query,
        'limit': limit,
        if (sinceId != null) 'sinceId': sinceId,
        if (untilId != null) 'untilId': untilId,
      };
      final List<dynamic> res = await http.send<List<dynamic>>(
        '/notes/search',
        method: 'POST',
        body: body,
        options: const core.RequestOptions(authRequired: true, idempotent: true),
      );
      return res.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    } catch (e) {
      throw mapAnyToKitException(e, endpoint: '/notes/search');
    }
  }

  /// タグ検索（`/api/notes/search-by-tag`）
  ///
  /// - 処理内容: 指定タグを含むノートを検索する
  /// - ページング: `limit`/`sinceId`/`untilId`
  /// - 認証: 必須（アクセストークン）
  /// - 例外: 失敗時は `MisskeyApiKitException` に正規化
  Future<List<NoteJson>> searchByTag({required String tag, int limit = 30, String? sinceId, String? untilId}) async {
    try {
      final Map<String, dynamic> body = <String, dynamic>{
        'tag': tag,
        'limit': limit,
        if (sinceId != null) 'sinceId': sinceId,
        if (untilId != null) 'untilId': untilId,
      };
      final List<dynamic> res = await http.send<List<dynamic>>(
        '/notes/search-by-tag',
        method: 'POST',
        body: body,
        options: const core.RequestOptions(authRequired: true, idempotent: true),
      );
      return res.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    } catch (e) {
      throw mapAnyToKitException(e, endpoint: '/notes/search-by-tag');
    }
  }

  /// 返信一覧（`/api/notes/replies`）
  ///
  /// - 処理内容: 対象ノートへの返信ノートを取得する
  /// - ページング: `limit`/`sinceId`/`untilId`
  /// - 認証: 必須（アクセストークン）
  /// - 例外: 失敗時は `MisskeyApiKitException` に正規化
  Future<List<NoteJson>> replies({required String noteId, int limit = 30, String? sinceId, String? untilId}) async {
    try {
      final Map<String, dynamic> body = <String, dynamic>{
        'noteId': noteId,
        'limit': limit,
        if (sinceId != null) 'sinceId': sinceId,
        if (untilId != null) 'untilId': untilId,
      };
      final List<dynamic> res = await http.send<List<dynamic>>(
        '/notes/replies',
        method: 'POST',
        body: body,
        options: const core.RequestOptions(authRequired: true, idempotent: true),
      );
      return res.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    } catch (e) {
      throw mapAnyToKitException(e, endpoint: '/notes/replies');
    }
  }

  /// リノート一覧（`/api/notes/renotes`）
  ///
  /// - 処理内容: 対象ノートをリノートしたノートの一覧を取得する
  /// - ページング: `limit`/`sinceId`/`untilId`
  /// - 認証: 必須（アクセストークン）
  /// - 例外: 失敗時は `MisskeyApiKitException` に正規化
  Future<List<NoteJson>> renotes({required String noteId, int limit = 30, String? sinceId, String? untilId}) async {
    try {
      final Map<String, dynamic> body = <String, dynamic>{
        'noteId': noteId,
        'limit': limit,
        if (sinceId != null) 'sinceId': sinceId,
        if (untilId != null) 'untilId': untilId,
      };
      final List<dynamic> res = await http.send<List<dynamic>>(
        '/notes/renotes',
        method: 'POST',
        body: body,
        options: const core.RequestOptions(authRequired: true, idempotent: true),
      );
      return res.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    } catch (e) {
      throw mapAnyToKitException(e, endpoint: '/notes/renotes');
    }
  }

  /// ノートの投票に投票する（`/api/notes/polls/vote`）
  ///
  /// - 処理内容: 指定ノートの投票に選択肢インデックスで投票する
  /// - 入力: `noteId` は対象ノートのID、`choice` は 0 始まりの選択肢インデックス
  /// - 認証: 必須（アクセストークン）
  /// - 例外: 失敗時は `MisskeyApiKitException` に正規化
  Future<void> pollsVote({required String noteId, required int choice}) async {
    try {
      // 成功時はHTTP 204 (No Content) を返すため、レスポンスボディは空 (null)
      await http.send<Object?>(
        '/notes/polls/vote',
        method: 'POST',
        body: <String, dynamic>{'noteId': noteId, 'choice': choice},
        options: const core.RequestOptions(authRequired: true),
      );
    } catch (e) {
      throw mapAnyToKitException(e, endpoint: '/notes/polls/vote');
    }
  }

  /// 投票付きノートのおすすめを取得（`/api/notes/polls/recommendation`）
  ///
  /// - 処理内容: 投票を含むおすすめノートを取得して返す
  /// - ページング: `sinceId`/`untilId` を任意指定可能
  /// - 例外: 失敗時は `MisskeyApiKitException` に正規化
  Future<List<NoteJson>> pollsRecommendation({int limit = 30, String? sinceId, String? untilId}) async {
    try {
      final Map<String, dynamic> body = <String, dynamic>{
        'limit': limit,
        if (sinceId != null) 'sinceId': sinceId,
        if (untilId != null) 'untilId': untilId,
      };

      final List<dynamic> res = await http.send<List<dynamic>>(
        '/notes/polls/recommendation',
        method: 'POST',
        body: body,
        options: const core.RequestOptions(authRequired: true, idempotent: true),
      );

      return res.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    } catch (e) {
      throw mapAnyToKitException(e, endpoint: '/notes/polls/recommendation');
    }
  }

  /// ホームタイムラインを取得（`/api/notes/timeline`）
  Future<List<NoteJson>> timelineHome({
    int limit = 30,
    String? sinceId,
    String? untilId,
    bool? withRenotes,
    bool? withFiles,
  }) async {
    return _fetchTimeline(
      path: '/notes/timeline',
      limit: limit,
      sinceId: sinceId,
      untilId: untilId,
      withRenotes: withRenotes,
      withFiles: withFiles,
    );
  }

  /// グローバルタイムラインを取得（`/api/notes/global-timeline`）
  Future<List<NoteJson>> timelineGlobal({
    int limit = 30,
    String? sinceId,
    String? untilId,
    bool? withRenotes,
    bool? withFiles,
  }) async {
    return _fetchTimeline(
      path: '/notes/global-timeline',
      limit: limit,
      sinceId: sinceId,
      untilId: untilId,
      withRenotes: withRenotes,
      withFiles: withFiles,
    );
  }

  /// ハイブリッドタイムラインを取得（`/api/notes/hybrid-timeline`）
  Future<List<NoteJson>> timelineHybrid({
    int limit = 30,
    String? sinceId,
    String? untilId,
    bool? withRenotes,
    bool? withReplies,
    bool? withFiles,
  }) async {
    return _fetchTimeline(
      path: '/notes/hybrid-timeline',
      limit: limit,
      sinceId: sinceId,
      untilId: untilId,
      withRenotes: withRenotes,
      withReplies: withReplies,
      withFiles: withFiles,
    );
  }

  /// ローカルタイムラインを取得（`/api/notes/local-timeline`）
  Future<List<NoteJson>> timelineLocal({
    int limit = 30,
    String? sinceId,
    String? untilId,
    bool? withRenotes,
    bool? withReplies,
    bool? withFiles,
  }) async {
    return _fetchTimeline(
      path: '/notes/local-timeline',
      limit: limit,
      sinceId: sinceId,
      untilId: untilId,
      withRenotes: withRenotes,
      withReplies: withReplies,
      withFiles: withFiles,
    );
  }

  /// ユーザー名/ホストからユーザーIDへ解決する
  ///
  /// - 入力例: 'librarian', 'librarian@misskey.io', '@librarian@misskey.io'
  /// - 失敗時の挙動: 個別トークンの解決失敗はスキップし、
  ///   `http.config.enableLog` が有効な場合のみデバッグログを出力（結果には含めない）
  Future<List<String>> resolveUsernamesToIds(List<String> tokens) async {
    final List<String> results = <String>[];
    for (final String raw in tokens) {
      final String trimmed = raw.trim();
      if (trimmed.isEmpty) continue;
      String username = trimmed;
      String? host;
      if (username.startsWith('@')) {
        username = username.substring(1);
      }
      if (username.contains('@')) {
        final parts = username.split('@');
        if (parts.length >= 2) {
          username = parts.first;
          host = parts.sublist(1).join('@');
        }
      }

      try {
        final List<dynamic> res = await http.send<List<dynamic>>(
          '/users/search-by-username-and-host',
          method: 'POST',
          body: <String, dynamic>{'username': username, if (host != null && host.isNotEmpty) 'host': host, 'limit': 1},
          options: const core.RequestOptions(authRequired: true),
        );
        if (res.isNotEmpty && res.first is Map) {
          final Map<String, dynamic> user = (res.first as Map).cast<String, dynamic>();
          final String id = (user['id'] ?? '').toString();
          if (id.isNotEmpty) results.add(id);
        }
      } catch (e) {
        // 個別解決失敗はスキップ（必要時のみデバッグログ）
        if (http.config.enableLog) {
          (http.logger ?? const core.StdoutLogger()).debug(
            'resolveUsernamesToIds: failed to resolve token="$trimmed": $e',
          );
        }
      }
    }
    return results;
  }

  Future<List<NoteJson>> _fetchTimeline({
    required String path,
    required int limit,
    String? sinceId,
    String? untilId,
    bool? withRenotes,
    bool? withReplies,
    bool? withFiles,
  }) async {
    try {
      final Map<String, dynamic> body = <String, dynamic>{
        'limit': limit,
        if (sinceId != null) 'sinceId': sinceId,
        if (untilId != null) 'untilId': untilId,
        if (withRenotes != null) 'withRenotes': withRenotes,
        if (withReplies != null) 'withReplies': withReplies,
        if (withFiles != null) 'withFiles': withFiles,
      };

      final List<dynamic> res = await http.send<List<dynamic>>(
        path,
        method: 'POST',
        body: body,
        options: const core.RequestOptions(authRequired: true, idempotent: true),
      );

      return res.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    } catch (e) {
      throw mapAnyToKitException(e, endpoint: path);
    }
  }
}
