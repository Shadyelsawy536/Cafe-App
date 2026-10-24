import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
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
import 'features/ordering/models/branding.dart';
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

  // Supabase is required by the ordering app, so initialize it before
  // runApp. Firebase is only required for push notifications and must
  // not delay the first frame; initialize it after the UI starts.

  final supabaseStopwatch = Stopwatch()..start();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );

  supabaseStopwatch.stop();

  StartupMetrics.log(
    'Supabase.initialize COMPLETE '
    '(${supabaseStopwatch.elapsedMilliseconds}ms)',
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

    WidgetsBinding.instance.endOfFrame.then((_) {
      StartupMetrics.log(
        'FIRST FRAME END OF FRAME',
      );
    });
  });

  // Firebase + push setup is intentionally deferred until after runApp.
  // A Firebase initialization/permission/network delay must not hold up
  // the catalog's first frame.
  WidgetsBinding.instance.endOfFrame.then((_) {
    Future<void>.delayed(const Duration(seconds: 3), () {
      unawaited(
        _initializeFirebaseAndNotifications(
          Supabase.instance.client,
        ),
      );
    });
  });
}

Future<void> _initializeFirebaseAndNotifications(
  SupabaseClient supabase,
) async {
  final stopwatch = Stopwatch()..start();

  try {
    // White-label: every restaurant app has its own google-services.json /
    // GoogleService-Info.plist, so prefer the native config. Fall back to the
    // generated firebase_options.dart (original Cafe app, web).
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      try {
        await Firebase.initializeApp();
      } catch (_) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    }

    StartupMetrics.log(
      'Firebase.initializeApp COMPLETE '
      '(${stopwatch.elapsedMilliseconds}ms, background)',
    );

    await PushNotificationService(supabase).initialize();

    StartupMetrics.log(
      'Push notification initialization COMPLETE '
      '(${stopwatch.elapsedMilliseconds}ms, background)',
    );
  } catch (error, stackTrace) {
    debugPrint('Background Firebase/push initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
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
  Branding? _themeBranding;
  late ThemeData _lightTheme;
  late ThemeData _darkTheme;

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
      onPromotion: (promotion) {
        if (!mounted) return;

        _controller.promotion = promotion;
        _controller.refreshUi();
      },
      onAvailability: (availability) {
        if (!mounted) return;

        _controller.availability = availability;
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
      child: Selector<OrderingController, (Branding, ThemeMode)>(
        selector: (_, controller) => (controller.branding, controller.themeMode),
        builder: (context, data, _) {
          final (branding, themeMode) = data;

          // ColorScheme.fromSeed is expensive. Rebuild themes only when the
          // branding object actually changes, not on every cart/realtime
          // notification.
          if (!identical(_themeBranding, branding)) {
            _themeBranding = branding;
            _lightTheme = AppTheme.light(branding);
            _darkTheme = AppTheme.dark(branding);
          }

          return MaterialApp(
            title: 'Cafe',
            debugShowCheckedModeBanner: false,
            theme: _lightTheme,
            darkTheme: _darkTheme,
            themeMode: themeMode,
            home: const WelcomeSplash(),
          );
        },
      ),
    );
  }
}

// ============================================================
// Welcome Splash
// ============================================================

class WelcomeSplash extends StatefulWidget {
  const WelcomeSplash({super.key});

  @override
  State<WelcomeSplash> createState() => _WelcomeSplashState();
}

class _WelcomeSplashState extends State<WelcomeSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    StartupMetrics.log(
      'WelcomeSplash.initState',
    );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _animationController.forward();

    // Keep the Welcome screen short and smooth.
    Future.delayed(
      const Duration(milliseconds: 600),
      () {
        if (!mounted) return;

        StartupMetrics.log(
          'WelcomeSplash -> MainShell',
        );

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const MainShell(),
            transitionDuration: const Duration(
              milliseconds: 250,
            ),
            reverseTransitionDuration: Duration.zero,
            transitionsBuilder: (
              _,
              animation,
              __,
              child,
            ) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Text(
            'Welcome',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}