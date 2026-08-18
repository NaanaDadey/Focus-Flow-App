import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants.dart';

/// Thin wrapper around Supabase initialization so `main.dart` stays clean
/// and every service can grab the client via [SupabaseConfig.client].
class SupabaseConfig {
  SupabaseConfig._();

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser => client.auth.currentUser;

  static bool get isLoggedIn => currentUser != null;
}
