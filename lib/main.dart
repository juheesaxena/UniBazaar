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
import 'package:unibazaar/features/categories/product_detail_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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

  late final FirebaseDatabase _db;

  @override
  void initState() {
    super.initState();

    _db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          'https://unibazaar-73dd2-default-rtdb.asia-southeast1.firebasedatabase.app',
    );

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

    final snap = await _db.ref('users/${user.uid}').get();
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
    final size = MediaQuery.of(context).size;

    final String avatarInitial = (_userName != null && _userName!.isNotEmpty)
        ? _userName![0].toUpperCase()
        : 'U';

    final int crossAxisCount = size.width < 600 ? 2 : 3;

    return Scaffold(
      body: Stack(
        children: [
          // MAIN HOME CONTENT
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
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
                      SizedBox(
                        height: 28,
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
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'All Listings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // GRID of listings
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: StreamBuilder<DatabaseEvent>(
                      stream: _db.ref('listings').onValue,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text('Error loading listings'),
                          );
                        }
                        if (!snapshot.hasData ||
                            snapshot.data!.snapshot.value == null) {
                          return const Center(child: Text('No listings yet'));
                        }

                        final raw =
                            snapshot.data!.snapshot.value
                                as Map<dynamic, dynamic>;
                        final entries = raw.entries.toList()
                          ..sort((a, b) {
                            final am = a.value as Map;
                            final bm = b.value as Map;
                            final at = (am['createdAt'] ?? 0) as int;
                            final bt = (bm['createdAt'] ?? 0) as int;
                            return bt.compareTo(at); // newest first
                          });

                        return GridView.builder(
                          itemCount: entries.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.75,
                              ),
                          itemBuilder: (context, index) {
                            final listing =
                                entries[index].value as Map<dynamic, dynamic>;

                            final title =
                                (listing['productName'] ?? '') as String;
                            final description =
                                (listing['description'] ?? '') as String;
                            final price = (listing['price'] ?? 0).toDouble();
                            final condition =
                                (listing['condition'] ?? '') as String;
                            final category =
                                (listing['category'] ?? '') as String;
                            final negotiable =
                                (listing['negotiable'] ?? true) as bool;
                            final college =
                                (listing['college'] ?? '') as String;

                            final images =
                                (listing['images'] ?? []) as List<dynamic>;
                            final thumbUrl = images.isNotEmpty
                                ? images.first as String
                                : '';

                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailScreen(
                                      categoryName: category,
                                      title: title,
                                      description: description,
                                      price: price,
                                      condition: condition,
                                      imageUrl: thumbUrl,
                                      isNegotiable: negotiable,
                                      college: college,
                                    ),
                                  ),
                                );
                              },
                              child: _ListingGridCard(
                                productName: title,
                                priceText: '₹ ${price.toStringAsFixed(0)}',
                                thumbnailUrl: thumbUrl.isNotEmpty
                                    ? thumbUrl
                                    : null,
                                college: college,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
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

class _ListingGridCard extends StatelessWidget {
  final String productName;
  final String priceText;
  final String? thumbnailUrl;
  final String college;

  const _ListingGridCard({
    required this.productName,
    required this.priceText,
    this.thumbnailUrl,
    this.college = '',
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final imgSize = size.width * 0.28;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: thumbnailUrl != null
                ? Image.network(
                    thumbnailUrl!,
                    width: double.infinity,
                    height: imgSize,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: double.infinity,
                    height: imgSize,
                    color: Colors.grey.shade300,
                  ),
          ),
          const SizedBox(height: 6),
          if (college.isNotEmpty)
            Text(
              college,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (college.isNotEmpty) const SizedBox(height: 2),
          Text(
            productName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Text(priceText, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
