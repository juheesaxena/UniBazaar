import 'package:flutter/material.dart';
import 'features/categories/category_listings_screen.dart';

class SearchScreen extends StatefulWidget {
  final String avatarInitial;

  const SearchScreen({super.key, required this.avatarInitial});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
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
              // Top bar: back arrow + title + avatar
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Categories',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  CircleAvatar(child: Text(widget.avatarInitial)),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _CategoryTile(
                      label: 'Electronics',
                      color: const Color(0xFFB8E6FF),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CategoryListingsScreen(
                              category: 'Electronics',
                            ),
                          ),
                        );
                      },
                    ),
                    _CategoryTile(
                      label: 'Household',
                      color: const Color(0xFFFFF3B0),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CategoryListingsScreen(
                              category: 'Household',
                            ),
                          ),
                        );
                      },
                    ),
                    _CategoryTile(
                      label: 'Fitness',
                      color: const Color(0xFFFFB3B8),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CategoryListingsScreen(
                              category: 'Fitness',
                            ),
                          ),
                        );
                      },
                    ),
                    _CategoryTile(
                      label: 'Beauty',
                      color: const Color(0xFFFFB3FF),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CategoryListingsScreen(
                              category: 'Beauty',
                            ),
                          ),
                        );
                      },
                    ),
                    _CategoryTile(
                      label: 'Two Wheelers',
                      color: const Color(0xFFB8FFB8),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CategoryListingsScreen(
                              category: 'Two Wheelers',
                            ),
                          ),
                        );
                      },
                    ),
                    _CategoryTile(
                      label: 'Kitchen',
                      color: const Color(0xFFB8C8FF),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CategoryListingsScreen(
                              category: 'Kitchen',
                            ),
                          ),
                        );
                      },
                    ),
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
  final VoidCallback onTap;

  const _CategoryTile({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
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
      ),
    );
  }
}
