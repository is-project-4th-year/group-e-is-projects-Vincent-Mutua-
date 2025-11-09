import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:is_application/core/routing/app_router.dart';
import 'package:is_application/core/theme/app_theme.dart';
// Import and initialize Firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  // We need to initialize Firebase *before* running the app
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
    // Watch your providers
    final theme = ref.watch(appThemeProvider);
    final router = ref.watch(goRouterProvider); // 1. Watch the router provider

    // 2. Change MaterialApp to MaterialApp.router
    return MaterialApp.router(
      title: 'ADHD Support App',
      debugShowCheckedModeBanner: false,
      theme: theme,
      
      // 3. Set the routerConfig
      routerConfig: router,
    );
  }
}
