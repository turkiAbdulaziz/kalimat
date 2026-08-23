/// Supabase project configuration.
///
/// The anon (publishable) key is safe to ship in the client — data access is
/// governed by RLS and security-definer RPCs. Values can also be injected at
/// build time: flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
library;

const String kSupabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: '', // TODO(M3): paste project URL
);

const String kSupabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: '', // TODO(M3): paste anon/publishable key
);

/// When false the app runs fully offline (bundled words, local stats).
bool get isSupabaseConfigured =>
    kSupabaseUrl.isNotEmpty && kSupabaseAnonKey.isNotEmpty;
