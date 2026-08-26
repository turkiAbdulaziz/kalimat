/// Supabase project configuration.
///
/// The anon (publishable) key is safe to ship in the client — data access is
/// governed by RLS and security-definer RPCs. Values are injected at build
/// time: flutter run --dart-define-from-file=env/dev.json (see that file).
///
/// Defaults stay EMPTY so `flutter test` runs unconfigured — the whole test
/// suite depends on that (flow gating, stats dialog, sync are all offline
/// under test). Don't hardcode credentials here.
library;

const String kSupabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: '',
);

const String kSupabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: '',
);

/// When false the app runs fully offline (bundled words, local stats).
bool get isSupabaseConfigured =>
    kSupabaseUrl.isNotEmpty && kSupabaseAnonKey.isNotEmpty;
