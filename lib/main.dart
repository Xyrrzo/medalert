import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/app_role.dart';
import 'pages/auth_pages.dart';
import 'pages/role_home_router.dart';
import 'services/auth_service.dart';
import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MedAlertApp());
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
      home: const StartupGate(),
    );
  }
}

class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  Object? _error;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _ready = false;
      _error = null;
    });
    try {
      await dotenv.load(fileName: '.env');
      await Supabase.initialize(
        url: dotenv.env['SUPABASE_URL']!,
        anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      );
      if (mounted) setState(() => _ready = true);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return const SplashGate();
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                const Text('MedAlert could not finish starting.'),
                const SizedBox(height: 8),
                Text('Details: $_error', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _initialize,
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});
  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400))
    ..forward();
  bool _done = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1900), () {
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        child: _done
            ? const AuthGate(key: ValueKey('auth'))
            : _SplashScreen(
                animation: _animation, key: const ValueKey('splash')),
      );
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen({required this.animation, super.key});
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppConstants.redGradient),
          child: Center(
            child: FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
              child: ScaleTransition(
                scale: Tween<double>(begin: .82, end: 1).animate(
                    CurvedAnimation(
                        parent: animation, curve: Curves.easeOutBack)),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: .18),
                                blurRadius: 24,
                                offset: const Offset(0, 10))
                          ]),
                      child: const Icon(Icons.health_and_safety_rounded,
                          color: AppConstants.redPrimary, size: 64)),
                  const SizedBox(height: 22),
                  const Text('MedAlert',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .4)),
                  const SizedBox(height: 6),
                  Text('CARE • COMMUNITY • CONNECTION',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: .86),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 32),
                  const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.white)),
                ]),
              ),
            ),
          ),
        ),
      );
}

class _AuthGateState extends State<AuthGate> {
  AppRole? _role;
  bool _loading = true;
  bool _failed = false;
  String? _activeUserId;
  late final StreamSubscription<AuthState> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription =
        AuthService.instance.authChanges.listen((_) => _resolveRole());
    _resolveRole();
  }

  Future<void> _resolveRole() async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      if (mounted)
        setState(() {
          _role = null;
          _loading = false;
          _failed = false;
          _activeUserId = null;
        });
      return;
    }
    if (_activeUserId == user.id && !_loading) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final role = await AuthService.instance.loadRole(user.id);
      if (!mounted) return;
      setState(() {
        _role = role;
        _loading = false;
        _activeUserId = user.id;
      });
    } catch (_) {
      await AuthService.instance.signOut();
      if (mounted)
        setState(() {
          _role = null;
          _loading = false;
          _failed = true;
          _activeUserId = null;
        });
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_role == null)
      return LoginPage(
          errorMessage: _failed
              ? 'Your access profile could not be loaded. Please sign in again.'
              : null);
    return RoleHomeRouter(role: _role!);
  }
}
