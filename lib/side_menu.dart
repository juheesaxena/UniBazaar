import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'search_screen.dart';
import 'features/sell/create_listing_screen.dart';

class SideMenu extends StatelessWidget {
  final VoidCallback onClose;
  final String? userName;
  final String? phone;

  const SideMenu({super.key, required this.onClose, this.userName, this.phone});

  @override
  Widget build(BuildContext context) {
    final displayName = userName ?? 'Guest';
    final displayPhone = phone ?? '';
    final avatarInitial = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : 'U';

    return Material(
      color: const Color(0xFFB7DFA3), // Light green background
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                displayPhone,
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),

              const SizedBox(height: 20),
              const Divider(color: Colors.white70),
              const SizedBox(height: 20),

              // MENU ITEMS
              _menuItem("Browse by College"),
              _menuItem("Filters"),
              _menuItem(
                "Categories",
                onTap: () {
                  onClose(); // close drawer
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
                "Sell your item",
                onTap: () {
                  onClose(); // close drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateListingScreen(),
                    ),
                  );
                },
              ),

              _menuItem("Saves"),

              const Spacer(),

              // LOG OUT BUTTON
              GestureDetector(
                onTap: () async {
                  onClose(); // close drawer
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
                      color: Color(0xFFFF7F7F), // soft red
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuItem(String name, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
