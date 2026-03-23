class Env {
  const Env._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static void validate() {
    if (supabaseUrl.isEmpty) {
      throw Exception('Brak SUPABASE_URL w --dart-define.');
    }

    if (supabaseAnonKey.isEmpty) {
      throw Exception('Brak SUPABASE_ANON_KEY w --dart-define.');
    }
  }
}