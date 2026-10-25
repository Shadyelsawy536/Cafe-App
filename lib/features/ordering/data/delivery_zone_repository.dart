import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/tenant_config.dart';
import '../models/delivery_zone.dart';

class DeliveryZoneRepository {
  DeliveryZoneRepository({
    SupabaseClient? client,
  }) : _client =
            client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<DeliveryZone?> findForCurrentLocation({
    required double latitude,
    required double longitude,
  }) async {
    final data = await _client.rpc(
      'find_delivery_zone_for_restaurant',
      params: {
        'p_restaurant_id':
            TenantConfig.restaurantId,
        'p_latitude': latitude,
        'p_longitude': longitude,
      },
    );

    final rows = data as List<dynamic>;

    if (rows.isEmpty) {
      return null;
    }

    return DeliveryZone.fromMap(
      Map<String, dynamic>.from(
        rows.first as Map,
      ),
    );
  }
}
