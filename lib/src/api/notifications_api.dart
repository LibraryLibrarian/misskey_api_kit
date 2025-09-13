import 'package:misskey_api_core/misskey_api_core.dart' as core;

import '../core/error/misskey_api_kit_exception.dart';

/// 通知関連の高レベルAPIエントリ
///
/// - 役割: Notifications系エンドポイントをSDK視点で提供
/// - 実処理: 下層の `MisskeyHttpClient` に委譲
class NotificationsApi {
  final core.MisskeyHttpClient http;

  /// コンストラクタ
  const NotificationsApi({required this.http});

  /// 通知一覧を取得（/api/i/notifications）
  ///
  /// - ページング: `sinceId` より新規、`untilId` より古い方向に取得
  /// - リトライ: 読み取り系のため `idempotent=true`
  Future<List<Map<String, dynamic>>> list({String? sinceId, String? untilId, int limit = 30}) async {
    try {
      final Map<String, dynamic> body = <String, dynamic>{
        'limit': limit,
        if (sinceId != null) 'sinceId': sinceId,
        if (untilId != null) 'untilId': untilId,
      };
      final List<dynamic> res = await http.send<List<dynamic>>(
        '/i/notifications',
        method: 'POST',
        body: body,
        options: const core.RequestOptions(authRequired: true, idempotent: true),
      );
      return res.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    } catch (e) {
      throw mapAnyToKitException(e, endpoint: '/i/notifications');
    }
  }

  /// グループ化された通知を取得（/api/i/notifications-grouped）
  ///
  /// - ページング: `sinceId` より新規、`untilId` より古い方向に取得
  /// - フィルタ: フォロー中のみ（`following`）、通知タイプの包含/除外（`includeTypes`/`excludeTypes`）
  Future<List<Map<String, dynamic>>> listGrouped({
    int limit = 30,
    String? sinceId,
    String? untilId,
    bool? following,
    bool? markAsRead,
    List<String>? includeTypes,
    List<String>? excludeTypes,
  }) async {
    try {
      final Map<String, dynamic> body = <String, dynamic>{
        'limit': limit,
        if (sinceId != null) 'sinceId': sinceId,
        if (untilId != null) 'untilId': untilId,
        if (following != null) 'following': following,
        if (markAsRead != null) 'markAsRead': markAsRead,
        if (includeTypes != null && includeTypes.isNotEmpty) 'includeTypes': includeTypes,
        if (excludeTypes != null && excludeTypes.isNotEmpty) 'excludeTypes': excludeTypes,
      };

      final List<dynamic> res = await http.send<List<dynamic>>(
        '/i/notifications-grouped',
        method: 'POST',
        body: body,
        options: core.RequestOptions(authRequired: true, idempotent: markAsRead != true),
      );
      return res.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    } catch (e) {
      throw mapAnyToKitException(e, endpoint: '/i/notifications-grouped');
    }
  }

  /// 全通知を既読にする（/api/i/read-all-notifications）
  Future<void> readAll() async {
    try {
      await http.send<Map>(
        '/i/read-all-notifications',
        method: 'POST',
        body: const <String, dynamic>{},
        options: const core.RequestOptions(authRequired: true),
      );
    } catch (e) {
      throw mapAnyToKitException(e, endpoint: '/i/read-all-notifications');
    }
  }

  /// 通知を個別に既読にする（/api/i/read-notification）
  Future<void> read(String notificationId) async {
    try {
      await http.send<Map>(
        '/i/read-notification',
        method: 'POST',
        body: <String, dynamic>{'notificationId': notificationId},
        options: const core.RequestOptions(authRequired: true),
      );
    } catch (e) {
      throw mapAnyToKitException(e, endpoint: '/i/read-notification');
    }
  }
}
