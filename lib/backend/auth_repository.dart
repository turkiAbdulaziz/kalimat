/// Account upgrade: link Google / Apple identities onto the anonymous user
/// (preserving uid, server results, and streak history), with the
/// "identity already linked elsewhere" fallback of switching accounts.
///
/// Console prerequisites (user checklist, companion plan §11):
/// - Supabase dashboard: Anonymous sign-ins ON, Manual linking ON,
///   Google provider ON (Web client ID in Authorized Client IDs),
///   Apple provider ON (Services ID, Team ID, Key ID, .p8 secret)
/// - Google Cloud: Web client ID (used as serverClientId below) +
///   Android client ID with package name & SHA-1s
/// - Apple Developer: App ID w/ Sign in with Apple, Services ID with the
///   Supabase callback URL, a .p8 key
library;

import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';
import 'supabase_service.dart';

/// Google Cloud WEB client ID (not the Android one). Also add it to the
/// Supabase Google provider's Authorized Client IDs.
const String kGoogleWebClientId = String.fromEnvironment(
  'GOOGLE_WEB_CLIENT_ID',
  defaultValue: '', // TODO(M4): paste web client ID
);

/// Apple Services ID (Android/web flow) + Supabase callback URL.
const String kAppleServiceId = String.fromEnvironment(
  'APPLE_SERVICE_ID',
  defaultValue: '', // TODO(M4): e.g. com.kalimat.game.signin
);

/// Google appears in the UI only once its client ID is configured; without
/// it [AuthRepository.linkGoogle] can only fail, and a dead button is an App
/// Review rejection. Apple has no such gate — on iOS it needs only the
/// entitlement, and the Android web flow degrades to a failure line.
final bool kGoogleSignInAvailable = kGoogleWebClientId.isNotEmpty;

enum LinkOutcome {
  /// Identity linked onto the current (anonymous) user — uid preserved.
  linked,

  /// Signed straight into an existing (non-anonymous) session's provider.
  switchedAccount,

  /// Identity already belongs to another user. The credential is held;
  /// call [confirmSwitch] after the user approves abandoning this
  /// device's anonymous progress.
  alreadyLinkedElsewhere,

  /// User dismissed the provider UI.
  cancelled,

  failed,
}

class AuthRepository {
  bool _googleReady = false;

  // Held credential for the confirm-switch step.
  OAuthProvider? _pendingProvider;
  String? _pendingIdToken;
  String? _pendingNonce;

  /// Null when Supabase isn't configured (Supabase.instance would throw).
  User? get currentUser =>
      isSupabaseConfigured ? SupabaseService.client.auth.currentUser : null;

  bool get isAnonymous => currentUser?.isAnonymous ?? true;

  Future<void> _initGoogle() async {
    if (_googleReady) return;
    await GoogleSignIn.instance.initialize(serverClientId: kGoogleWebClientId);
    _googleReady = true;
  }

  /// google_sign_in v7 flow: authenticate() then link/sign in with the
  /// returned ID token.
  Future<LinkOutcome> linkGoogle() async {
    if (kGoogleWebClientId.isEmpty) return LinkOutcome.failed;
    try {
      await _initGoogle();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) return LinkOutcome.failed;
      return await _linkOrSwitch(OAuthProvider.google, idToken: idToken);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return LinkOutcome.cancelled;
      }
      debugPrint('kalimat: google sign-in failed: $e');
      return LinkOutcome.failed;
    } catch (e) {
      debugPrint('kalimat: google sign-in failed: $e');
      return LinkOutcome.failed;
    }
  }

  /// Apple flow with SHA-256 nonce; on Android this runs the web flow via
  /// the Services ID.
  Future<LinkOutcome> linkApple() async {
    try {
      final rawNonce = _generateNonce();
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [AppleIDAuthorizationScopes.email],
        nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
        webAuthenticationOptions: Platform.isIOS || kAppleServiceId.isEmpty
            ? null
            : WebAuthenticationOptions(
                clientId: kAppleServiceId,
                redirectUri: Uri.parse('$kSupabaseUrl/auth/v1/callback'),
              ),
      );
      final idToken = credential.identityToken;
      if (idToken == null) return LinkOutcome.failed;
      return await _linkOrSwitch(
        OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return LinkOutcome.cancelled;
      }
      debugPrint('kalimat: apple sign-in failed: $e');
      return LinkOutcome.failed;
    } catch (e) {
      debugPrint('kalimat: apple sign-in failed: $e');
      return LinkOutcome.failed;
    }
  }

  Future<LinkOutcome> _linkOrSwitch(
    OAuthProvider provider, {
    required String idToken,
    String? nonce,
  }) async {
    final auth = SupabaseService.client.auth;
    try {
      if (isAnonymous) {
        // Requires "Enable Manual Linking" in the dashboard.
        await auth.linkIdentityWithIdToken(
          provider: provider,
          idToken: idToken,
          nonce: nonce,
        );
        return LinkOutcome.linked;
      }
      await auth.signInWithIdToken(
        provider: provider,
        idToken: idToken,
        nonce: nonce,
      );
      return LinkOutcome.switchedAccount;
    } on AuthException catch (e) {
      // Identity already linked to another user: hold the credential and
      // let the UI confirm the switch (abandons this device's anonymous
      // progress) before signing in.
      final already = e.message.toLowerCase().contains('already');
      if (already && isAnonymous) {
        _pendingProvider = provider;
        _pendingIdToken = idToken;
        _pendingNonce = nonce;
        return LinkOutcome.alreadyLinkedElsewhere;
      }
      debugPrint('kalimat: link failed: ${e.message}');
      return LinkOutcome.failed;
    }
  }

  /// Completes the account switch after user confirmation.
  Future<bool> confirmSwitch() async {
    final provider = _pendingProvider;
    final idToken = _pendingIdToken;
    if (provider == null || idToken == null) return false;
    try {
      await SupabaseService.client.auth.signInWithIdToken(
        provider: provider,
        idToken: idToken,
        nonce: _pendingNonce,
      );
      return true;
    } on AuthException catch (e) {
      debugPrint('kalimat: account switch failed: ${e.message}');
      return false;
    } finally {
      _pendingProvider = null;
      _pendingIdToken = null;
      _pendingNonce = null;
    }
  }

  /// Signs out of the linked account. The next [SupabaseService.ensureSession]
  /// (sync, or the next sign-in attempt) creates a fresh anonymous session.
  Future<void> signOut() async {
    if (!isSupabaseConfigured) return;
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Google may never have been initialized on this device.
    }
    try {
      await SupabaseService.client.auth.signOut();
    } catch (e) {
      debugPrint('kalimat: sign-out failed: $e');
    }
  }

  /// Deletes the account server-side (`delete_account()` — 0007; cascades
  /// through profiles, results, friendships and duels), then drops the
  /// local session. Local scope on purpose: the server session vanished
  /// with the user, so a global sign-out would only 403. Returns false and
  /// changes nothing when the RPC fails.
  Future<bool> deleteAccount() async {
    if (!isSupabaseConfigured) return false;
    try {
      await SupabaseService.client.rpc('delete_account');
    } catch (e) {
      debugPrint('kalimat: account deletion failed: $e');
      return false;
    }
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Google may never have been initialized on this device.
    }
    try {
      await SupabaseService.client.auth.signOut(scope: SignOutScope.local);
    } catch (e) {
      debugPrint('kalimat: local sign-out after deletion failed: $e');
    }
    return true;
  }

  Future<void> updateDisplayName(String name) async {
    final uid = currentUser?.id;
    if (uid == null) return;
    await SupabaseService.client
        .from('profiles')
        .update({'display_name': name})
        .eq('id', uid);
  }

  Future<String?> fetchDisplayName() async {
    final uid = currentUser?.id;
    if (uid == null) return null;
    final row = await SupabaseService.client
        .from('profiles')
        .select('display_name')
        .eq('id', uid)
        .maybeSingle();
    return row?['display_name'] as String?;
  }

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }
}
