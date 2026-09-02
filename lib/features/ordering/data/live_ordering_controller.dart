import 'package:flutter/foundation.dart';

import '../../core/config/tenant_config.dart';
import 'product_repository.dart';
import 'dashboard_config_realtime.dart';
import '../models/branding.dart';
import '../models/cafe_location.dart';
import '../models/experience_settings.dart';
import '../presentation/controllers/ordering_controller.dart';

/// OrderingController with live Restaurant Dashboard configuration.
class LiveOrderingController extends OrderingController {
  LiveOrderingController({required ProductRepository repository})
      : _configRealtime = DashboardConfigRealtime(
          repository: repository,
          onSettings: (_) {},
          onBranding: (_) {},
          onLocations: (_) {},
        ),
        super(repository: repository) {
    _configRealtime = DashboardConfigRealtime(
      repository: repository,
      onSettings: (value) {
        settings = value;
        notifyListeners();
      },
      onBranding: (value) {
        branding = value;
        notifyListeners();
      },
      onLocations: (value) {
        locations = value;
        notifyListeners();
      },
    );
    _configRealtime.start();
  }

  late DashboardConfigRealtime _configRealtime;

  @override
  void dispose() {
    _configRealtime.dispose();
    super.dispose();
  }
}
