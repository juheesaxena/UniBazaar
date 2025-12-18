import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:unibazaar/features/chat/chat_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String categoryName;
  final String title;
  final String description;
  final double price;
  final String condition;
  final List<String> images; // multiple images
  final bool isNegotiable;
  final String college;
  final String sellerUid;
  final String sellerName;
  final String listingId; // id of this listing in /listings

  const ProductDetailScreen({
    super.key,
    required this.categoryName,
    required this.title,
    required this.description,
    required this.price,
    required this.condition,
    required this.images,
    this.isNegotiable = true,
    this.college = '',
    required this.sellerUid,
    required this.sellerName,
    required this.listingId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openFullScreenGallery(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenImageViewer(
          images: widget.images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    final hasImages = images.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- TOP BAR ----------
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    height: 28,
                    child: Image.asset(
                      'assets/images/unibazaar_splash.jpeg',
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Text(
                '${widget.categoryName} /',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),

              const SizedBox(height: 12),

              // ---------- PRODUCT IMAGES CAROUSEL + SAVE BUTTON ----------
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: hasImages
                          ? PageView.builder(
                              controller: _pageController,
                              itemCount: images.length,
                              onPageChanged: (index) {
                                setState(() => _currentPage = index);
                              },
                              itemBuilder: (context, index) {
                                final url = images[index];
                                return GestureDetector(
                                  onTap: () => _openFullScreenGallery(index),
                                  child: Hero(
                                    tag:
                                        'product_image_${widget.listingId}_$index',
                                    child: Image.network(
                                      url,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(color: Colors.grey.shade300),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _SaveButton(listingId: widget.listingId),
                    ),
                  ],
                ),
              ),

              if (hasImages) ...[
                const SizedBox(height: 8),
                // ---------- DOT INDICATOR ----------
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(images.length, (index) {
                    final isActive = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: isActive ? 16 : 8,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.black : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    '${_currentPage + 1} / ${images.length}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // ---------- TAGS ----------
              Row(
                children: [
                  if (widget.college.isNotEmpty) _tagChip(widget.college),
                  if (widget.college.isNotEmpty && widget.isNegotiable)
                    const SizedBox(width: 8),
                  if (widget.isNegotiable) _tagChip('Negotiable'),
                ],
              ),

              const SizedBox(height: 12),

              // ---------- TITLE + PRICE ----------
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),

              const Text(
                'Price :',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                '₹ ${widget.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Condition :',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Text(widget.condition, style: const TextStyle(fontSize: 16)),

              const SizedBox(height: 16),

              const Text(
                'Description :',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(widget.description, style: const TextStyle(fontSize: 15)),

              const SizedBox(height: 24),

              // ---------- CHAT BUTTON ----------
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB7DFA3),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          peerUid: widget.sellerUid,
                          peerName: widget.sellerName,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Chat with Seller',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tagChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFB7DFA3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

// ---------- FULL SCREEN IMAGE VIEWER ----------

class _FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenImageViewer({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('${_currentIndex + 1} / ${images.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: images.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (context, index) {
          final url = images[index];
          return Center(
            child: Hero(
              tag:
                  'product_image_${ModalRoute.of(context)?.settings.arguments ?? ''}_$index',
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SaveButton extends StatefulWidget {
  final String listingId;

  const _SaveButton({required this.listingId});

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final app = Firebase.app();
    final db = FirebaseDatabase.instanceFor(
      app: app,
      databaseURL:
          'https://unibazaar-73dd2-default-rtdb.asia-southeast1.firebasedatabase.app',
    );

    final snap =
        await db.ref('users/${user.uid}/saves/${widget.listingId}').get();
    if (mounted) {
      setState(() => _saved = snap.exists);
    }
  }

  Future<void> _toggleSave() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final app = Firebase.app();
    final db = FirebaseDatabase.instanceFor(
      app: app,
      databaseURL:
          'https://unibazaar-73dd2-default-rtdb.asia-southeast1.firebasedatabase.app',
    );

    final ref = db.ref('users/${user.uid}/saves/${widget.listingId}');
    if (_saved) {
      await ref.remove();
    } else {
      await ref.set(true);
    }
    if (mounted) {
      setState(() => _saved = !_saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.4),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _toggleSave,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              _saved ? Icons.bookmark : Icons.bookmark_border,
              key: ValueKey<bool>(_saved),
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
