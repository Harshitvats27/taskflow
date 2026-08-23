import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/di/providers.dart';
import 'core/theme/app_theme.dart';

import 'core/router/app_router.dart';
import 'presentation/providers/auth_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  
  runApp(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: const TaskFlowApp(),
  ));
}

class TaskFlowApp extends ConsumerWidget {
  const TaskFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'TaskFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      // ── Activity Listener ─────────────────────────────────────────
      // Intercepts every pointer-down event at the root level and resets
      // the 5-minute inactivity timer in AuthNotifier.
      // This is the ONLY way the timer is reset — no per-screen code needed.
      builder: (context, child) {
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) =>
              ref.read(authNotifierProvider.notifier).recordActivity(),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
