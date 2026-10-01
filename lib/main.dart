import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pages/home_page.dart';
import 'services/notification_service.dart';
import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  
  await _ensureAuthenticated();

  await NotificationService.instance.init();

  runApp(const MedAlertApp());
}

Future<void> _ensureAuthenticated() async {
  final client = Supabase.instance.client;
  

  if (client.auth.currentUser != null) return;
  
  try {
    
    await client.auth.signInAnonymously();
    print('✅ Anonymous auth successful: ${client.auth.currentUser?.id}');
  } catch (e) {
    print('❌ Auth failed: $e');
  
  }
}

class MedAlertApp extends StatelessWidget {
  const MedAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.redPrimary,
          primary: AppConstants.redPrimary,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppConstants.redPrimary,
            foregroundColor: Colors.white,
          ),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          indicatorColor: AppConstants.redBright,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const GradientAppBar({super.key, required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      actions: actions,
      flexibleSpace: Container(decoration: AppConstants.gradientBox(radius: 0)),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}