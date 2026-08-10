import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/theme/app_theme.dart';
import 'config/routes/app_router.dart';
import 'core/database/app_database.dart';
import 'core/services/demo_data_seeder.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final demoDataSeededProvider = FutureProvider<bool>((ref) async {
  try {
    final db = ref.read(databaseProvider);
    final seeder = DemoDataSeeder(db);
    await seeder.seed();
  } catch (e) {
    // On web, database may not be available - mock data will be used instead
    if (!kIsWeb) rethrow;
  }
  return true;
});

class TutorScheduleApp extends ConsumerWidget {
  const TutorScheduleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: '家教日程管家',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
    );
  }
}

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
