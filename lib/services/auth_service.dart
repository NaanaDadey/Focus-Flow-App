import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../core/supabase_config.dart';
import '../models/user_profile_model.dart';

/// App-level auth error with a UI-friendly message. Named `AppAuthException`
/// to avoid clashing with `supabase_flutter`'s own `AuthException`.
class AppAuthException implements Exception {
  final String message;
  AppAuthException(this.message);
  @override
  String toString() => message;
}

/// Wraps Supabase email/password auth and profile fetch/update.
/// Screens and providers talk to this class only — never to
/// `Supabase.instance` directly — so the auth backend could be swapped
/// later without touching UI code.
class AuthService {
  final supa.SupabaseClient _client = SupabaseConfig.client;

  Stream<supa.AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  supa.User? get currentUser => _client.auth.currentUser;

  bool get isLoggedIn => currentUser != null;

  Future<supa.User> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final res = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName.trim()},
      );
      if (res.user == null) {
        throw AppAuthException('Sign-up failed. Please try again.');
      }
      return res.user!;
    } on supa.AuthException catch (e) {
      throw AppAuthException(_friendlyMessage(e.message));
    } on AppAuthException {
      rethrow;
    } catch (_) {
      throw AppAuthException(
          'Could not reach the server. Check your connection and try again.');
    }
  }

  Future<supa.User> signIn(
      {required String email, required String password}) async {
    try {
      final res = await _client.auth
          .signInWithPassword(email: email.trim(), password: password);
      if (res.user == null) {
        throw AppAuthException('Invalid email or password.');
      }
      return res.user!;
    } on supa.AuthException catch (e) {
      throw AppAuthException(_friendlyMessage(e.message));
    } on AppAuthException {
      rethrow;
    } catch (_) {
      throw AppAuthException(
          'Could not reach the server. Check your connection and try again.');
    }
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> sendPasswordReset(String email) async {
    await _client.auth.resetPasswordForEmail(email.trim());
  }

  Future<UserProfileModel> fetchProfile(String userId) async {
    final row =
        await _client.from('profiles').select().eq('id', userId).single();
    return UserProfileModel.fromMap(row);
  }

  Future<UserProfileModel> updateProfile(UserProfileModel profile) async {
    final map = profile.toMap()
      ..remove('id')
      ..remove('email');
    final row = await _client
        .from('profiles')
        .update(map)
        .eq('id', profile.id)
        .select()
        .single();
    return UserProfileModel.fromMap(row);
  }

  String _friendlyMessage(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('invalid login credentials')) {
      return 'Incorrect email or password.';
    }
    if (lower.contains('already registered') || lower.contains('exists')) {
      return 'An account with this email already exists.';
    }
    if (lower.contains('password')) {
      return 'Password must be at least 6 characters.';
    }
    return raw;
  }
}
