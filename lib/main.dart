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
import 'package:unibazaar/features/chat/inbox_screen.dart';

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

// ------------------------------------------------------------
// SPLASH SCREEN
// ------------------------------------------------------------

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
      Navigator.pushReplacementNamed(
        context,
        user != null ? '/home' : '/login',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: Image.asset('assets/images/unibazaar_splash.jpeg')),
    );
  }
}

// ------------------------------------------------------------
// HOME SCREEN
// ------------------------------------------------------------

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

    final map = Map<String, dynamic>.from(snap.value as Map);
    setState(() {
      _userName = map['name'] ?? "User";
      _phone = map['phone'] ?? "";
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final crossAxisCount = size.width < 600 ? 2 : 3;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // ---------------- TOP BAR ----------------
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() => _isMenuOpen = true);
                          _controller.forward();
                        },
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
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SearchScreen(
                                avatarInitial:
                                    _userName != null && _userName!.isNotEmpty
                                    ? _userName![0]
                                    : "U",
                              ),
                            ),
                          );
                        },
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const InboxScreen(),
                            ),
                          );
                        },
                        child: const CircleAvatar(
                          radius: 18,
                          backgroundImage: AssetImage(
                            'assets/images/dm_pic.jpeg',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ---------------- ALL LISTINGS ----------------
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

                Expanded(
                  child: StreamBuilder<DatabaseEvent>(
                    stream: _db.ref('listings').onValue,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData ||
                          snapshot.data!.snapshot.value == null) {
                        return const Center(child: Text("No listings yet"));
                      }

                      final raw =
                          snapshot.data!.snapshot.value
                              as Map<dynamic, dynamic>;

                      final entries = raw.entries.toList()
                        ..sort((a, b) {
                          return ((b.value['createdAt'] ?? 0) as int).compareTo(
                            (a.value['createdAt'] ?? 0) as int,
                          );
                        });

                      return GridView.builder(
                        itemCount: entries.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemBuilder: (context, index) {
                          final listing =
                              entries[index].value as Map<dynamic, dynamic>;

                          final sellerUid =
                              listing['sellerUid'] ?? listing['ownerId'] ?? "";

                          final images =
                              (listing['images'] ?? []) as List<dynamic>;

                          final thumb = images.isNotEmpty
                              ? images[0] as String
                              : "";

                          return InkWell(
                            onTap: () async {
                              print(
                                "➡️ Listing tapped. sellerUid = $sellerUid",
                              );

                              String sellerName = "User";

                              try {
                                final snap = await _db
                                    .ref("users/$sellerUid/name")
                                    .get();

                                if (snap.exists && snap.value != null) {
                                  sellerName = snap.value.toString();
                                }
                              } catch (e) {
                                print("🔥 ERROR fetching seller name: $e");
                              }

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailScreen(
                                    categoryName: listing['category'] ?? "",
                                    title: listing['productName'] ?? "",
                                    description: listing['description'] ?? "",
                                    price: (listing['price'] ?? 0).toDouble(),
                                    condition: listing['condition'] ?? "",
                                    images: images.cast<String>(),
                                    isNegotiable: listing['negotiable'] ?? true,
                                    college: listing['college'] ?? "",
                                    sellerUid: sellerUid,
                                    sellerName: sellerName,
                                    listingId: entries[index].key as String,
                                  ),
                                ),
                              );
                            },
                            child: _ListingGridCard(
                              productName: listing['productName'] ?? "",
                              priceText:
                                  "₹ ${(listing['price'] ?? 0).toString()}",
                              thumbnailUrl: thumb,
                              college: listing['college'] ?? "",
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ---------------- SIDE MENU OVERLAY ----------------
          if (_isMenuOpen)
            GestureDetector(
              onTap: () {
                _controller.reverse();
                setState(() => _isMenuOpen = false);
              },
              child: Container(color: Colors.black.withOpacity(0.4)),
            ),

          AnimatedBuilder(
            animation: _slide,
            builder: (_, __) {
              final menuWidth = size.width * 0.78;
              final offset = -menuWidth + (menuWidth * _slide.value);
              return Transform.translate(
                offset: Offset(offset, 0),
                child: SizedBox(
                  width: menuWidth,
                  child: SideMenu(
                    onClose: () {
                      _controller.reverse();
                      setState(() => _isMenuOpen = false);
                    },
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

// ------------------------------------------------------------
// GRID CARD
// ------------------------------------------------------------

class _ListingGridCard extends StatelessWidget {
  final String productName;
  final String priceText;
  final String? thumbnailUrl;
  final String college;

  const _ListingGridCard({
    required this.productName,
    required this.priceText,
    this.thumbnailUrl,
    this.college = "",
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
            child: thumbnailUrl != null && thumbnailUrl!.isNotEmpty
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
            ),

          const SizedBox(height: 2),

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
