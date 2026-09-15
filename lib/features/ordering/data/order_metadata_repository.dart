import 'package:supabase_flutter/supabase_flutter.dart';

/// Persists checkout-only metadata through a server-side RPC so customers
/// cannot directly update arbitrary order rows.
class OrderMetadataRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> save({
    required String orderId,
    required String notes,
    DateTime? scheduledFor,
  }) async {
    await _client.rpc('set_order_metadata', params: {
      'p_order_id': orderId,
      'p_customer_notes': notes,
      'p_scheduled_for': scheduledFor?.toUtc().toIso8601String(),
    });
  }
}
