import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/tenant_config.dart';
import '../models/branding.dart';
import '../models/cafe_location.dart';
import '../models/experience_settings.dart';
import 'product_repository.dart';

/// Keeps customer-facing dashboard configuration synchronized with Supabase.
/// Realtime events are treated as invalidation signals; the repository then
/// re-fetches the canonical state through the normal RLS-protected path.
class DashboardConfigRealtime {
  DashboardConfigRealtime({
    required ProductRepository repository,
    required ValueChanged<ExperienceSettings> onSettings,
    required ValueChanged<Branding> onBranding,
    required ValueChanged<List<CafeLocation>> onLocations,
  })  : _repository = repository,
        _onSettings = onSettings,
        _onBranding = onBranding,
        _onLocations = onLocations;

  final ProductRepository _repository;
  final ValueChanged<ExperienceSettings> _onSettings;
  final ValueChanged<Branding> _onBranding;
  final ValueChanged<List<CafeLocation>> _onLocations;
  final SupabaseClient _client = Supabase.instance.client;

  RealtimeChannel? _channel;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;

    final channel = _client.channel(
      'cafe-dashboard-config-${TenantConfig.restaurantId}',
    );
    _channel = channel;

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'restaurant_settings',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'restaurant_id',
        value: TenantConfig.restaurantId,
      ),
      callback: (payload) {
        debugPrint('REALTIME CONFIG: settings ${payload.eventType}');
        unawaited(_reloadSettings());
      },
    );

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'restaurant_branding',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'restaurant_id',
        value: TenantConfig.restaurantId,
      ),
      callback: (payload) {
        debugPrint('REALTIME CONFIG: branding ${payload.eventType}');
        unawaited(_reloadBranding());
      },
    );

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'restaurant_locations',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'restaurant_id',
        value: TenantConfig.restaurantId,
      ),
      callback: (payload) {
        debugPrint('REALTIME CONFIG: locations ${payload.eventType}');
        unawaited(_reloadLocations());
      },
    );

    channel.subscribe((status, error) {
      debugPrint('REALTIME CONFIG STATUS: $status');
      if (error != null) {
        debugPrint('REALTIME CONFIG ERROR: $error');
      }
      if (status == RealtimeSubscribeStatus.subscribed) {
        debugPrint('REALTIME CONFIG: CONNECTED');
      }
    });
  }

  Future<void> _reloadSettings() async {
    try {
      _onSettings(await _repository.fetchSettings());
    } catch (e) {
      debugPrint('REALTIME CONFIG: settings refresh failed: $e');
    }
  }

  Future<void> _reloadBranding() async {
    try {
      _onBranding(await _repository.fetchBranding());
    } catch (e) {
      debugPrint('REALTIME CONFIG: branding refresh failed: $e');
    }
  }

  Future<void> _reloadLocations() async {
    try {
      _onLocations(await _repository.fetchLocations());
    } catch (e) {
      debugPrint('REALTIME CONFIG: locations refresh failed: $e');
    }
  }

  Future<void> dispose() async {
    final channel = _channel;
    _channel = null;
    _started = false;
    if (channel != null) {
      await _client.removeChannel(channel);
    }
  }
}
