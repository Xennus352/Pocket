import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'config/colors.dart';
import 'config/theme.dart';
import 'providers/transaction_provider.dart';
import 'providers/user_provider.dart';
import 'screens/home_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/update_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyExpenseApp());
}

class MyExpenseApp extends StatelessWidget {
  const MyExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()..init()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
      ],
      child: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          return MaterialApp(
            title: 'My Expense',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            scrollBehavior: const _NoOverscrollBehavior(),
            home: const AppEntry(),
          );
        },
      ),
    );
  }
}

class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool _providersReady = false;
  bool _animationDone = false;

  bool get _ready => _providersReady && _animationDone;

  @override
  void initState() {
    super.initState();
    _initProviders();
  }

  Future<void> _initProviders() async {
    final userProvider = context.read<UserProvider>();
    await userProvider.init();
    if (!mounted) return;
    final txnProvider = context.read<TransactionProvider>();
    txnProvider.userProvider = userProvider;
    if (userProvider.onboardingComplete) {
      await txnProvider.init();
    }
    if (mounted) setState(() => _providersReady = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) {
      final userProvider = context.read<UserProvider>();
      if (!userProvider.onboardingComplete) {
        return const OnboardingScreen();
      }
      // Check for updates after first build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        UpdateService.checkForUpdates(context);
      });
      return const MainShell();
    }
    return _SplashScreen(onFinished: () {
      if (mounted) setState(() => _animationDone = true);
    });
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    AnalyticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        elevation: 2,
        indicatorColor: AppColors.primaryBlue.withValues(alpha: 0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined, color: AppColors.textSecondary),
            selectedIcon: const Icon(Icons.home_rounded, color: AppColors.primaryBlue),
            label: 'Home',
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined, color: AppColors.textSecondary),
            selectedIcon: const Icon(Icons.bar_chart_rounded, color: AppColors.primaryBlue),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}

class _SplashScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const _SplashScreen({required this.onFinished});

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        widget.onFinished();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.bgStart, AppColors.bgEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Lottie.asset(
            'assets/animations/splash.json',
            controller: _controller,
            onLoaded: (composition) {
              _controller.duration = composition.duration;
              _controller.forward();
            },
            width: 280,
            height: 280,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _NoOverscrollBehavior extends ScrollBehavior {
  const _NoOverscrollBehavior();

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
