import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/config/supabase_config.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/ordering/data/dashboard_config_realtime.dart';
import 'features/ordering/data/product_repository.dart';
import 'features/ordering/data/supabase_product_repository.dart';
import 'features/ordering/presentation/controllers/ordering_controller.dart';
import 'features/ordering/presentation/screens/main_shell.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase / FCM first.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Supabase.
  final supabase = await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // Initialize Push Notifications
  // using the already initialized Supabase client.
  final pushNotificationService =
  PushNotificationService(supabase.client);

  await pushNotificationService.initialize();

  runApp(const CafeApp());
}

class CafeApp extends StatefulWidget {
  const CafeApp({super.key});

  @override
  State<CafeApp> createState() => _CafeAppState();
}

class _CafeAppState extends State<CafeApp> {
  late final ProductRepository _repository;
  late final OrderingController _controller;
  late final DashboardConfigRealtime _configRealtime;

  @override
  void initState() {
    super.initState();

    _repository = SupabaseProductRepository();

    _controller = OrderingController(
      repository: _repository,
    );

    _configRealtime = DashboardConfigRealtime(
      repository: _repository,
      onSettings: (settings) {
        if (!mounted) return;

        _controller.settings = settings;
        _controller.notifyListeners();
      },
      onBranding: (branding) {
        if (!mounted) return;

        _controller.branding = branding;
        _controller.notifyListeners();
      },
      onLocations: (locations) {
        if (!mounted) return;

        _controller.locations = locations;
        _controller.notifyListeners();
      },
    )..start();

    _controller.loadData();
  }

  @override
  void dispose() {
    _configRealtime.dispose();
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: _controller,
        ),
        ChangeNotifierProvider(
          create: (_) => AuthController(),
        ),
      ],
      child: Consumer<OrderingController>(
        builder: (context, controller, _) {
          return MaterialApp(
            title: 'Cafe',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(
              controller.branding,
            ),
            darkTheme: AppTheme.dark(
              controller.branding,
            ),
            themeMode: controller.themeMode,
            home: const MainShell(),
          );
        },
      ),
    );
  }
}