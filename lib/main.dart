import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'auth/phone_signup_screen.dart';
import 'auth/phone_login_screen.dart';
import 'firebase_options.dart';
import 'side_menu.dart';
import 'search_screen.dart';

// Firebase singletons (optional)
final FirebaseAuth auth = FirebaseAuth.instance;
final FirebaseDatabase db = FirebaseDatabase.instanceFor(
  app: Firebase.app(),
  databaseURL:
      'https://unibazaar-73dd2-default-rtdb.asia-southeast1.firebasedatabase.app',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // TEMP: force sign‑out so splash goes to /login while developing
  await FirebaseAuth.instance.signOut();

  runApp(const UniBazaarApp());
}

class UniBazaarApp extends StatelessWidget {
  const UniBazaarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniBazaar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/login': (_) => const PhoneLoginScreen(),
        '/signup': (_) => const PhoneSignUpScreen(),
        '/home': (_) => const HomeScreen(),
      },
    );
  }
}

// ---------- SPLASH SCREEN ----------

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () async {
      if (!mounted) return;
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/unibazaar_splash.jpeg',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

// ---------- HOME SCREEN ----------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slide;
  bool _isMenuOpen = false;

  String? _userName;
  String? _phone;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _slide = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          'https://unibazaar-73dd2-default-rtdb.asia-southeast1.firebasedatabase.app',
    );

    final snap = await database.ref('users/${user.uid}').get();
    if (!snap.exists) return;

    final data = Map<String, dynamic>.from(snap.value as Map);
    setState(() {
      _userName = data['name'] as String?;
      _phone = data['phone'] as String?;
    });
  }

  void _openMenu() {
    setState(() => _isMenuOpen = true);
    _controller.forward();
  }

  void _closeMenu() async {
    await _controller.reverse();
    if (mounted) setState(() => _isMenuOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final double menuWidth = MediaQuery.of(context).size.width * 0.78;

    final String avatarInitial = (_userName != null && _userName!.isNotEmpty)
        ? _userName![0].toUpperCase()
        : 'U';

    return Scaffold(
      body: Stack(
        children: [
          // MAIN HOME CONTENT
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: _openMenu,
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.menu),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // REPLACE TEXT WITH LOGO IMAGE
                    SizedBox(
                      height: 28, // similar visual height to the text
                      child: Image.asset(
                        'assets/images/unibazaar_splash.jpeg',
                        fit: BoxFit.contain,
                      ),
                    ),

                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                SearchScreen(avatarInitial: avatarInitial),
                          ),
                        );
                      },
                    ),
                    CircleAvatar(child: Text(avatarInitial)),
                  ],
                ),
                const SizedBox(height: 30),
                const Text(
                  'Hot Deals',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                const _PlaceholderRow(),
                const SizedBox(height: 30),
                const Text(
                  'Newly Listed',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                const _PlaceholderRow(),
              ],
            ),
          ),

          // DARK OVERLAY
          if (_isMenuOpen)
            AnimatedBuilder(
              animation: _slide,
              builder: (_, __) => Opacity(
                opacity: _slide.value,
                child: GestureDetector(
                  onTap: _closeMenu,
                  child: Container(color: Colors.black.withOpacity(0.4)),
                ),
              ),
            ),

          // SLIDING SIDE MENU
          AnimatedBuilder(
            animation: _slide,
            builder: (_, __) {
              final offset = -menuWidth + (menuWidth * _slide.value);
              return Transform.translate(
                offset: Offset(offset, 0),
                child: SizedBox(
                  width: menuWidth,
                  child: SideMenu(
                    onClose: _closeMenu,
                    userName: _userName,
                    phone: _phone,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PlaceholderRow extends StatelessWidget {
  const _PlaceholderRow();

  @override
  Widget build(BuildContext context) {
    Widget card() => Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
    );

    Widget line() => Container(
      height: 12,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              card(),
              const SizedBox(height: 10),
              line(),
              const SizedBox(height: 6),
              line(),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              card(),
              const SizedBox(height: 10),
              line(),
              const SizedBox(height: 6),
              line(),
            ],
          ),
        ),
      ],
    );
  }
}
