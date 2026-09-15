import 'dashboard_config_realtime.dart';
import 'product_repository.dart';
import '../presentation/controllers/ordering_controller.dart';

/// OrderingController with live Restaurant Dashboard configuration.
class LiveOrderingController extends OrderingController {
  LiveOrderingController({required ProductRepository repository})
      : _repository = repository,
        super(repository: repository);

  final ProductRepository _repository;
  DashboardConfigRealtime? _configRealtime;

  void startDashboardRealtime() {
    _configRealtime ??= DashboardConfigRealtime(
      repository: _repository,
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
    _configRealtime!.start();
  }

  @override
  void dispose() {
    _configRealtime?.dispose();
    super.dispose();
  }
}
