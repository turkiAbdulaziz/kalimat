/// Supabase initialization + anonymous-first auth session.
library;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

class SupabaseService {
  /// Initializes the client. No-op when the project isn't configured.
  static Future<void> init() async {
    if (!isSupabaseConfigured) return;
    await Supabase.initialize(
      url: kSupabaseUrl,
      publishableKey: kSupabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  /// Everything works anonymously; sign-in upgrades come later (M4).
  /// Returns true when a session is available.
  static Future<bool> ensureSession() async {
    if (!isSupabaseConfigured) return false;
    if (client.auth.currentSession != null) return true;
    try {
      await client.auth.signInAnonymously();
      return true;
    } on AuthException catch (e) {
      // Anonymous sign-ins disabled or offline — keep playing offline.
      debugPrint('kalimat: anonymous sign-in failed: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('kalimat: anonymous sign-in failed: $e');
      return false;
    }
  }
}
