import 'package:flutter/material.dart';
import 'side_menu.dart';

void main() {
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
      home: const HomeScreen(),
    );
  }
}

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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _slide = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
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
    double menuWidth = MediaQuery.of(context).size.width * 0.78;

    return Scaffold(
      body: Stack(
        children: [
          // ----------------------------
          // MAIN HOME CONTENT
          // ----------------------------
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Top Row
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
                    const Text(
                      "UNIBAZAAR",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    const CircleAvatar(child: Text("A")),
                  ],
                ),

                const SizedBox(height: 30),

                // HOT DEALS
                const Text(
                  "Hot Deals",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                const _PlaceholderRow(),

                const SizedBox(height: 30),

                // NEWLY LISTED
                const Text(
                  "Newly Listed",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                const _PlaceholderRow(),
              ],
            ),
          ),

          // ----------------------------
          // DARK OVERLAY (tap to close)
          // ----------------------------
          if (_isMenuOpen)
            AnimatedBuilder(
              animation: _slide,
              builder: (_, __) => Opacity(
                opacity: _slide.value * 1,
                child: GestureDetector(
                  onTap: _closeMenu,
                  child: Container(
                    color: Colors.black.withOpacity(0.4),
                  ),
                ),
              ),
            ),

          // ----------------------------
          // SLIDING SIDE MENU
          // ----------------------------
          AnimatedBuilder(
            animation: _slide,
            builder: (_, __) {
              final offset = -menuWidth + (menuWidth * _slide.value);
              return Transform.translate(
                offset: Offset(offset, 0),
                child: SizedBox(
                  width: menuWidth,
                  child: SideMenu(onClose: _closeMenu),
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
