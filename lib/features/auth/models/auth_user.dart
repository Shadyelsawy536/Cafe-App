enum SignInMethod { email, google }

/// Local representation of the signed-in customer. Once Supabase Auth is
/// wired in, this maps directly onto Supabase's user/session object —
/// the shape here is deliberately what a real auth response looks like.
class AuthUser {
  final String id;
  final String name;
  final String email;
  final SignInMethod method;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.method,
  });
}
