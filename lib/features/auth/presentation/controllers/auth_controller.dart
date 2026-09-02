import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../models/auth_user.dart';

enum AuthStatus { idle, submitting }

/// Real Supabase Auth — email/password is fully live. Google Sign-In will
/// work once TWO things exist outside this code: (1) a Google Cloud OAuth
/// Client ID/Secret added to Supabase Auth's Google provider settings, and
/// (2) a mobile deep-link redirect URL configured for this app. Until
/// both exist, signInWithGoogle surfaces a clear "not set up yet" message
/// rather than faking a session.
class AuthController extends ChangeNotifier {
  AuthController() {
    _client.auth.onAuthStateChange.listen(
      (data) => _syncFromSession(data.session),
    );
    _syncFromSession(_client.auth.currentSession);
  }

  final supabase.SupabaseClient _client = supabase.Supabase.instance.client;

  AuthUser? currentUser;
  AuthStatus status = AuthStatus.idle;
  String? errorMessage;

  bool get isSignedIn => currentUser != null;

  Future<void> _syncFromSession(supabase.Session? session) async {
    final user = session?.user;

    if (user == null) {
      currentUser = null;
      notifyListeners();
      return;
    }

    String name = user.email?.split('@').first ?? 'there';

    try {
      final profile = await _client
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .maybeSingle();

      final fullName = profile?['full_name'] as String?;

      if (fullName != null && fullName.isNotEmpty) {
        name = fullName;
      }
    } catch (_) {
      // Non-fatal — falls back to the email-derived name above.
    }

    currentUser = AuthUser(
      id: user.id,
      name: name,
      email: user.email ?? '',
      method: user.appMetadata['provider'] == 'google'
          ? SignInMethod.google
          : SignInMethod.email,
    );

    notifyListeners();
  }

  Future<void> signInWithEmail(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      errorMessage = 'Enter your email and password';
      notifyListeners();
      return;
    }

    status = AuthStatus.submitting;
    errorMessage = null;
    notifyListeners();

    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      // _syncFromSession runs via the onAuthStateChange listener.
    } on supabase.AuthException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = 'Something went wrong. Please try again.';
    } finally {
      status = AuthStatus.idle;
      notifyListeners();
    }
  }

  Future<void> signUpWithEmail(
    String name,
    String email,
    String password,
  ) async {
    if (name.trim().isEmpty || email.trim().isEmpty) {
      errorMessage = 'Fill in all fields';
      notifyListeners();
      return;
    }

    if (password.length < 6) {
      errorMessage = 'Password must be at least 6 characters';
      notifyListeners();
      return;
    }

    status = AuthStatus.submitting;
    errorMessage = null;
    notifyListeners();

    try {
      // full_name in the signup metadata is read by the handle_new_user
      // trigger to populate profiles.full_name automatically.
      await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': name.trim()},
      );
    } on supabase.AuthException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = 'Something went wrong. Please try again.';
    } finally {
      status = AuthStatus.idle;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    status = AuthStatus.submitting;
    errorMessage = null;
    notifyListeners();

    try {
      await _client.auth.signInWithOAuth(
        supabase.OAuthProvider.google,
      );
    } catch (_) {
      errorMessage = "Google Sign-In isn't set up yet for this project.";
    } finally {
      status = AuthStatus.idle;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();

    // _syncFromSession clears currentUser via the onAuthStateChange listener.
  }
}