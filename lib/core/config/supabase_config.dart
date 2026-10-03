/// Supabase project connection details. The anon key is safe to embed in
/// the client — it grants nothing by itself; every table is protected by
/// RLS, and the anon role can't do anything the policies don't allow.
/// Never put the service_role key here or anywhere in the app.
class SupabaseConfig {
  static const url = 'https://rsajmvnbezztzdkbglbp.supabase.co';
  static const anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJzYWptdm5iZXp6dHpka2JnbGJwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY0NDA1MzcsImV4cCI6MjEwMjAxNjUzN30.pqOBqWwmbedn1CR-y0ZAFDHa3GZIWUKwqFmnyx0f4Os';
}
