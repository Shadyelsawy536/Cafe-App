import 'dart:async';
import 'dart:ui' as ui;

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

class StartupMetrics {
  StartupMetrics._();

  static final Stopwatch stopwatch = Stopwatch();

  static void start() {
    stopwatch
      ..reset()
      ..start();

    log('PROCESS START');
  }

  static void log(String message) {
    debugPrint(
      'STARTUP [${stopwatch.elapsedMilliseconds}ms] $message',
    );
  }

  static void stop() {
    if (stopwatch.isRunning) {
      stopwatch.stop();
    }
  }
}

Future<void> main() async {
  StartupMetrics.start();

  WidgetsFlutterBinding.ensureInitialized();

  StartupMetrics.log('WidgetsFlutterBinding initialized');

  // ------------------------------------------------------------
  // Firebase + Supabase initialization
  // ------------------------------------------------------------
  //
  // Both still start concurrently.
  // We are only measuring each one separately so we can identify
  // which initialization is responsible for startup time.
  // ------------------------------------------------------------

  final firebaseStopwatch = Stopwatch()..start();

  final firebaseFuture = Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).then((result) {
    firebaseStopwatch.stop();

    StartupMetrics.log(
      'Firebase.initializeApp COMPLETE '
          '(${firebaseStopwatch.elapsedMilliseconds}ms)',
    );

    return result;
  });

  final supabaseStopwatch = Stopwatch()..start();

  final supabaseFuture = Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  ).then((result) {
    supabaseStopwatch.stop();

    StartupMetrics.log(
      'Supabase.initialize COMPLETE '
          '(${supabaseStopwatch.elapsedMilliseconds}ms)',
    );

    return result;
  });

  final results = await Future.wait([
    firebaseFuture,
    supabaseFuture,
  ]);

  final supabase = results[1] as Supabase;

  StartupMetrics.log(
    'Firebase + Supabase BOTH COMPLETE',
  );

  // ------------------------------------------------------------
  // Frame timing instrumentation
  // ------------------------------------------------------------

  WidgetsBinding.instance.addTimingsCallback(
    _onFrameTimings,
  );

  StartupMetrics.log(
    'Frame timing callback registered',
  );

  // ------------------------------------------------------------
  // Start Flutter application
  // ------------------------------------------------------------

  runApp(const CafeApp());

  StartupMetrics.log(
    'runApp() returned',
  );

  // ------------------------------------------------------------
  // First Flutter frame
  // ------------------------------------------------------------

  WidgetsBinding.instance.addPostFrameCallback((_) {
    StartupMetrics.log(
      'FIRST FRAME CALLBACK',
    );

    // Wait until Flutter finishes the frame.
    WidgetsBinding.instance.endOfFrame.then((_) {
      StartupMetrics.log(
        'FIRST FRAME END OF FRAME',
      );
    });
  });

  // ------------------------------------------------------------
  // Push notifications intentionally stay in background.
  // They must NOT block startup.
  // ------------------------------------------------------------

  unawaited(
    PushNotificationService(supabase.client).initialize(),
  );

  StartupMetrics.log(
    'Push notification initialization started in background',
  );
}

void _onFrameTimings(List<ui.FrameTiming> timings) {
  if (timings.isEmpty) {
    return;
  }

  for (final timing in timings) {
    final totalBuild =
        timing.buildDuration.inMicroseconds / 1000.0;

    final raster =
        timing.rasterDuration.inMicroseconds / 1000.0;

    final totalFrame =
        timing.totalSpan.inMicroseconds / 1000.0;

    // We only care about startup here.
    // Don't flood the console forever.
    if (StartupMetrics.stopwatch.elapsedMilliseconds < 5000) {
      StartupMetrics.log(
        'FRAME TIMING '
            'build=${totalBuild.toStringAsFixed(1)}ms '
            'raster=${raster.toStringAsFixed(1)}ms '
            'total=${totalFrame.toStringAsFixed(1)}ms',
      );
    }
  }
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

    StartupMetrics.log(
      'CafeApp.initState START',
    );

    // ----------------------------------------------------------
    // Repository
    // ----------------------------------------------------------

    final repositoryStopwatch = Stopwatch()..start();

    _repository = SupabaseProductRepository();

    repositoryStopwatch.stop();

    StartupMetrics.log(
      'SupabaseProductRepository created '
          '(${repositoryStopwatch.elapsedMilliseconds}ms)',
    );

    // ----------------------------------------------------------
    // Ordering Controller
    // ----------------------------------------------------------

    final controllerStopwatch = Stopwatch()..start();

    _controller = OrderingController(
      repository: _repository,
    );

    controllerStopwatch.stop();

    StartupMetrics.log(
      'OrderingController created '
          '(${controllerStopwatch.elapsedMilliseconds}ms)',
    );

    // ----------------------------------------------------------
    // Dashboard realtime
    // ----------------------------------------------------------

    final realtimeStopwatch = Stopwatch()..start();

    _configRealtime = DashboardConfigRealtime(
      repository: _repository,
      onSettings: (settings) {
        if (!mounted) return;

        _controller.settings = settings;
        _controller.refreshUi();
      },
      onBranding: (branding) {
        if (!mounted) return;

        _controller.branding = branding;
        _controller.refreshUi();
      },
      onLocations: (locations) {
        if (!mounted) return;

        _controller.locations = locations;
        _controller.refreshUi();
      },
    )..start();

    realtimeStopwatch.stop();

    StartupMetrics.log(
      'DashboardConfigRealtime.start() called '
          '(${realtimeStopwatch.elapsedMilliseconds}ms)',
    );

    // ----------------------------------------------------------
    // Initial data load
    // ----------------------------------------------------------

    final loadDataStopwatch = Stopwatch()..start();

    unawaited(
      _controller.loadData().then((_) {
        loadDataStopwatch.stop();

        StartupMetrics.log(
          'OrderingController.loadData() COMPLETE '
              '(${loadDataStopwatch.elapsedMilliseconds}ms)',
        );
      }).catchError((Object error, StackTrace stackTrace) {
        loadDataStopwatch.stop();

        StartupMetrics.log(
          'OrderingController.loadData() ERROR '
              'after ${loadDataStopwatch.elapsedMilliseconds}ms: '
              '$error',
        );

        return null;
      }),
    );

    StartupMetrics.log(
      'OrderingController.loadData() STARTED',
    );

    StartupMetrics.log(
      'CafeApp.initState END',
    );
  }

  @override
  void dispose() {
    StartupMetrics.log(
      'CafeApp.dispose()',
    );

    _configRealtime.dispose();
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    StartupMetrics.log(
      'CafeApp.build()',
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: _controller,
        ),
        ChangeNotifierProvider(
          create: (_) {
            StartupMetrics.log(
              'AuthController CREATED',
            );

            return AuthController();
          },
        ),
      ],
      child: Consumer<OrderingController>(
        builder: (context, controller, _) {
          StartupMetrics.log(
            'Consumer<OrderingController>.builder',
          );

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