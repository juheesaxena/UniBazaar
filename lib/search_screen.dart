import 'package:flutter/material.dart';

class SearchScreen extends StatelessWidget {
  final String avatarInitial;

  const SearchScreen({super.key, required this.avatarInitial});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: search bar + avatar
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const TextField(
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Search',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(child: Text(avatarInitial)),
                ],
              ),

              const SizedBox(height: 24),

              const Text(
                'Categories',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: const [
                    _CategoryTile(
                      label: 'Electronics',
                      color: Color(0xFFB8E6FF),
                    ),
                    _CategoryTile(label: 'Household', color: Color(0xFFFFF3B0)),
                    _CategoryTile(label: 'Fitness', color: Color(0xFFFFB3B8)),
                    _CategoryTile(label: 'Beauty', color: Color(0xFFFFB3FF)),
                    _CategoryTile(label: 'Bicycles', color: Color(0xFFB8FFB8)),
                    _CategoryTile(label: 'Kitchen', color: Color(0xFFB8C8FF)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String label;
  final Color color;

  const _CategoryTile({required this.label, required this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
