import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/tenant_config.dart';
import '../models/branding.dart';
import '../models/cafe_location.dart';
import '../models/experience_settings.dart';
import 'product_repository.dart';
import '../presentation/controllers/ordering_controller.dart';

/// Keeps customer-facing configuration in sync with the Restaurant Dashboard.
///
/// Realtime events are treated as invalidation signals; the canonical state is
/// always re-fetched through the normal repository/RLS path.
class DashboardConfigRealtime {
  DashboardConfigRealtime({
    required ProductRepository repository,
    required OrderingController controller,
  })  : _repository = repository,
        _controller = controller;

  final ProductRepository _repository;
  final OrderingController _controller;
  final SupabaseClient _client = Supabase.instance.client;

  RealtimeChannel? _channel;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;

    final channelName =
        'cafe-config-${TenantConfig.restaurantId}-${DateTime.now().microsecondsSinceEpoch}';
    final channel = _client.channel(channelName);
    _channel = channel;

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'restaurant_settings',
      callback: (payload) {
        debugPrint('REALTIME CONFIG: restaurant_settings ${payload.eventType}');
        unawaited(_reloadSettings());
      },
    );

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'restaurant_branding',
      callback: (payload) {
        debugPrint('REALTIME CONFIG: restaurant_branding ${payload.eventType}');
        unawaited(_reloadBranding());
      },
    );

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'restaurant_locations',
      callback: (payload) {
        debugPrint('REALTIME CONFIG: restaurant_locations ${payload.eventType}');
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
      final fresh = await _repository.fetchSettings();
      _controller.settings = fresh;
      _controller.notifyListeners();
      debugPrint('REALTIME CONFIG: settings refreshed');
    } catch (e) {
      debugPrint('REALTIME CONFIG: settings refresh failed: $e');
    }
  }

  Future<void> _reloadBranding() async {
    try {
      final fresh = await _repository.fetchBranding();
      _controller.branding = fresh;
      _controller.notifyListeners();
      debugPrint('REALTIME CONFIG: branding refreshed');
    } catch (e) {
      debugPrint('REALTIME CONFIG: branding refresh failed: $e');
    }
  }

  Future<void> _reloadLocations() async {
    try {
      final fresh = await _repository.fetchLocations();
      _controller.locations = fresh;
      _controller.notifyListeners();
      debugPrint('REALTIME CONFIG: locations refreshed (${fresh.length})');
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
