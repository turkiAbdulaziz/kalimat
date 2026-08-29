/// Friend graph RPCs (0005_challenge_functions.sql). Every call is guarded by
/// [isSupabaseConfigured] and fails soft — the UI shows an inline line, never
/// an exception.
library;

import 'package:flutter/foundation.dart';

import '../challenge/models.dart';
import 'supabase_config.dart';
import 'supabase_service.dart';

const Duration _kTimeout = Duration(seconds: 8);

class FriendsRepository {
  Future<List<Friend>> fetchFriends() async {
    final rows = await _rpc('get_friends');
    return rows == null ? const [] : rows.map(Friend.fromRow).toList();
  }

  Future<List<FriendRequest>> fetchRequests() async {
    final rows = await _rpc('get_friend_requests');
    return rows == null ? const [] : rows.map(FriendRequest.fromRow).toList();
  }

  Future<MyPlayerCard?> fetchMyCard() async {
    final rows = await _rpc('get_my_profile');
    if (rows == null || rows.isEmpty) return null;
    return MyPlayerCard.fromRow(rows.first);
  }

  /// The one cross-user lookup: the server matches the code, applies its own
  /// rate limit, and reports back what it did.
  Future<AddFriendResult> sendRequest(String code) async {
    final rows = await _rpc('send_friend_request', {'p_code': code});
    if (rows == null || rows.isEmpty) return AddFriendResult.failed;
    return AddFriendResult.fromName(rows.first['result'] as String?);
  }

  Future<bool> respond(String userId, {required bool accept}) async {
    final ok = await _rpc('respond_friend_request', {
      'p_user_id': userId,
      'p_accept': accept,
    });
    return ok != null;
  }

  Future<bool> remove(String userId) async {
    final ok = await _rpc('remove_friend', {'p_user_id': userId});
    return ok != null;
  }

  /// Returns null on any failure (offline, unconfigured, no session).
  Future<List<Map<String, dynamic>>?> _rpc(
    String name, [
    Map<String, Object?>? params,
  ]) async {
    if (!isSupabaseConfigured) return null;
    if (!await SupabaseService.ensureSession()) return null;
    try {
      final result = await SupabaseService.client
          .rpc<dynamic>(name, params: params)
          .timeout(_kTimeout);
      if (result is List) {
        return result.cast<Map<String, dynamic>>();
      }
      return const []; // void RPC: success with no rows
    } catch (e) {
      debugPrint('kalimat: $name failed: $e');
      return null;
    }
  }
}
