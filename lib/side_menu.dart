import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import 'search_screen.dart';
import 'features/sell/create_listing_screen.dart';
import 'features/sell/your_listings_screen.dart';
import 'features/categories/saved_listings_screen.dart';

class SideMenu extends StatelessWidget {
  final VoidCallback onClose;
  final String? userName;
  final String? phone;

  const SideMenu({
    super.key,
    required this.onClose,
    this.userName,
    this.phone,
  });

  // 🔥 OPEN SUGGESTIONS FORM
  Future<void> _openSuggestionsForm() async {
    const String formUrl = 'https://forms.gle/Hwhzz8Qv4dyBsKof8';
    final Uri uri = Uri.parse(formUrl);

    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      debugPrint('Could not launch suggestions form');
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = userName ?? 'Guest';
    final displayPhone = phone ?? '';
    final avatarInitial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Material(
      color: const Color(0xFFB7DFA3),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------- HEADER ----------------
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white,
                    child: Text(
                      avatarInitial,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (displayPhone.isNotEmpty)
                        Text(
                          displayPhone,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(color: Colors.white70),
              const SizedBox(height: 20),

              // ---------------- SELL / YOUR LISTINGS ----------------
              Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      onClose();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateListingScreen(),
                        ),
                      );
                    },
                    child: _pill(
                      text: 'Sell your item',
                      bg: Colors.white,
                      textColor: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      onClose();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const YourListingsScreen(),
                        ),
                      );
                    },
                    child: _pill(
                      text: 'Your listings',
                      bg: Colors.black87,
                      textColor: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ---------------- MENU ITEMS ----------------
              _menuItem(
                icon: Icons.category_outlined,
                title: 'Categories',
                onTap: () {
                  onClose();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SearchScreen(avatarInitial: avatarInitial),
                    ),
                  );
                },
              ),

              _menuItem(
                icon: Icons.bookmark_border,
                title: 'Saved',
                onTap: () {
                  onClose();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SavedListingsScreen(),
                    ),
                  );
                },
              ),

              _menuItem(
                icon: Icons.lightbulb_outline,
                title: 'Suggestions',
                onTap: () async {
                  onClose();
                  await _openSuggestionsForm();
                },
              ),

              const Spacer(),

              // ---------------- LOGOUT ----------------
              GestureDetector(
                onTap: () async {
                  onClose();
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Log out',
                    style: TextStyle(
                      color: Color(0xFFFF7F7F),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- HELPERS ----------------

  Widget _menuItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Colors.black87),
            const SizedBox(width: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill({
    required String text,
    required Color bg,
    required Color textColor,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
