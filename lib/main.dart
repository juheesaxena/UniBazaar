import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:unibazaar/services/chat_service.dart';

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

  // 🔥 MUST INITIALIZE CHAT SERVICE BEFORE runApp()
  ChatService.instance.init();

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

  final ChatService _chatService = ChatService.instance;
  Stream<int>? _unreadStream;

  @override
  void initState() {
    super.initState();

    // 🔥 ChatService already initialized in main(), but safe to leave here
    ChatService.instance.init();

    _db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          "https://unibazaar-73dd2-default-rtdb.asia-southeast1.firebasedatabase.app",
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _slide = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

    _loadUserProfile();

    // 🔥 unread count listener
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _unreadStream = _chatService.getUnreadMessageCount(user.uid);
    }
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await _db.ref('users/${user.uid}').get();
    if (!snap.exists) return;

    final data = Map<String, dynamic>.from(snap.value as Map);
    setState(() {
      _userName = data['name'] ?? "User";
      _phone = data['phone'] ?? "";
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
                                avatarInitial: (_userName?.isNotEmpty ?? false)
                                    ? _userName![0]
                                    : "U",
                              ),
                            ),
                          );
                        },
                      ),

                      // 🔥 DM ICON + BADGE
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const InboxScreen(),
                            ),
                          );
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const CircleAvatar(
                              radius: 18,
                              backgroundImage: AssetImage(
                                "assets/images/dm_pic.jpeg",
                              ),
                            ),
                            Positioned(
                              right: -4,
                              top: -4,
                              child: StreamBuilder<int>(
                                stream: _unreadStream,
                                builder: (context, snapshot) {
                                  final unread = snapshot.data ?? 0;

                                  if (unread == 0) {
                                    return const SizedBox.shrink();
                                  }

                                  return Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      unread.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ---------------- LISTINGS ----------------
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
                    stream: _db.ref("listings").onValue,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData ||
                          snapshot.data!.snapshot.value == null) {
                        return const Center(child: Text("No listings yet"));
                      }

                      final raw = snapshot.data!.snapshot.value
                          as Map<dynamic, dynamic>;
                      final entries = raw.entries.toList()
                        ..sort(
                          (a, b) => (b.value["createdAt"] ?? 0).compareTo(
                            a.value["createdAt"] ?? 0,
                          ),
                        );

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: GridView.builder(
                          itemCount: entries.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemBuilder: (context, index) {
                            final listing = entries[index].value as Map;

                            final sellerUid = listing["sellerUid"] ??
                                listing["ownerId"] ??
                                "";

                            final images =
                                (listing["images"] ?? []) as List<dynamic>;
                            final thumb = images.isNotEmpty ? images[0] : "";

                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailScreen(
                                      categoryName: listing["category"] ?? "",
                                      title: listing["productName"] ?? "",
                                      description: listing["description"] ?? "",
                                      price: (listing["price"] ?? 0).toDouble(),
                                      condition: listing["condition"] ?? "",
                                      images: images.cast<String>(),
                                      isNegotiable:
                                          listing["negotiable"] ?? true,
                                      college: listing["college"] ?? "",
                                      sellerUid: sellerUid,
                                      sellerName: listing["sellerName"] ??
                                          "Unknown Seller",
                                      listingId: entries[index].key as String,
                                    ),
                                  ),
                                );
                              },
                              child: _ListingGridCard(
                                productName: listing["productName"] ?? "",
                                priceText: "₹ ${(listing["price"] ?? 0)}",
                                thumbnailUrl: thumb,
                                college: listing["college"] ?? "",
                              ),
                            );
                          },
                        ),
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
              final offset = -menuWidth + menuWidth * _slide.value;

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
// GRID CARD WIDGET
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
    final imgSize = MediaQuery.of(context).size.width * 0.28;

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
                    height: imgSize,
                    width: double.infinity,
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
