import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'core/constants.dart';
import 'core/supabase_config.dart';
import 'services/local_storage_service.dart';
import 'services/notification_service.dart';
import 'providers/auth_provider.dart';
import 'providers/task_provider.dart';
import 'providers/timetable_provider.dart';
import 'providers/semester_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local storage boots first — the app must be fully usable offline /
  // as a guest even if Supabase or notification permissions never
  // resolve, so nothing here is allowed to block on the network.
  await LocalStorageService.init();
  await SupabaseConfig.initialize();
  await NotificationService.instance.init();
  await NotificationService.instance.requestPermissions();

  runApp(const FocusFlowApp());
}

class FocusFlowApp extends StatelessWidget {
  const FocusFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // AuthProvider is created first among the data providers since it
        // triggers the initial Supabase pull-sync that the others read
        // from indirectly via shared local storage.
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => TimetableProvider()),
        ChangeNotifierProvider(create: (_) => SemesterProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeProvider.mode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
