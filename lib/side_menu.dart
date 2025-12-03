import 'package:flutter/material.dart';

class SideMenu extends StatelessWidget {
  final VoidCallback onClose;
  final String? userName;
  final String? phone;

  const SideMenu({super.key, required this.onClose, this.userName, this.phone});

  @override
  Widget build(BuildContext context) {
    final displayName = userName ?? 'Guest';
    final displayPhone = phone ?? '';

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
              Divider(color: Colors.white70),
              const SizedBox(height: 20),

              // MENU ITEMS
              _menuItem("Browse by College"),
              _menuItem("Filters"),
              _menuItem("Categories"),
              _menuItem("Sell your item"),
              _menuItem("Saves"),

              const Spacer(),

              Row(
                children: const [
                  Icon(Icons.settings, color: Colors.black),
                  SizedBox(width: 10),
                  Text(
                    "Settings",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuItem(String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        name,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }
}
