import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/ordering/data/product_repository.dart';
import 'features/ordering/data/supabase_product_repository.dart';
import 'features/ordering/presentation/controllers/ordering_controller.dart';
import 'features/ordering/presentation/screens/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  runApp(const CafeApp());
}

class CafeApp extends StatelessWidget {
  const CafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ProductRepository repository = SupabaseProductRepository();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => OrderingController(repository: repository)..loadData(),
        ),
        ChangeNotifierProvider(create: (_) => AuthController()),
      ],
      child: Consumer<OrderingController>(
        builder: (context, controller, _) {
          return MaterialApp(
            title: 'Cafe',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(controller.branding),
            darkTheme: AppTheme.dark(controller.branding),
            themeMode: controller.themeMode,
            home: const MainShell(),
          );
        },
      ),
    );
  }
}
