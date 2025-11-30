import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:is_application/core/routing/app_router.dart';
import 'package:is_application/core/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
// For AppleProvider, use DefaultAppleProvider
import 'package:is_application/core/services/notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enable App Check with debug provider for development
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  // Initialize Notifications
  final notificationService = NotificationService();
  await notificationService.init();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    
    // Watch the light and dark themes
    final lightTheme = ref.watch(appThemeProvider(Brightness.light));
    final darkTheme = ref.watch(appThemeProvider(Brightness.dark));
    final themeMode = ref.watch(appThemeModeProvider);

    return MaterialApp.router(
      title: 'ADHD Support App',
      debugShowCheckedModeBanner: false,
      
      // Apply the themes
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode, // This respects the device's setting
      
      routerConfig: router,
    );
  }
}