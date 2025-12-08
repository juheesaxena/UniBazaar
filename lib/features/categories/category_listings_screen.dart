import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import 'product_detail_screen.dart';

class CategoryListingsScreen extends StatelessWidget {
  final String category;

  const CategoryListingsScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final app = Firebase.app();
    final db = FirebaseDatabase.instanceFor(
      app: app,
      databaseURL:
          'https://unibazaar-73dd2-default-rtdb.asia-southeast1.firebasedatabase.app',
    );

    final query = db.ref('listings').orderByChild('category').equalTo(category);

    return Scaffold(
      appBar: AppBar(
        title: Text(category),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: query.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading listings'));
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text('No items in this category yet'));
          }

          final raw = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final entries = raw.entries.toList()
            ..sort((a, b) {
              final am = a.value as Map;
              final bm = b.value as Map;
              final at = (am['createdAt'] ?? 0) as int;
              final bt = (bm['createdAt'] ?? 0) as int;
              return bt.compareTo(at); // newest first
            });

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = entries[index].value as Map<dynamic, dynamic>;
              final productName = (data['productName'] ?? '') as String;
              final description = (data['description'] ?? '') as String;
              final price = (data['price'] as num?)?.toDouble() ?? 0.0;
              final condition = (data['condition'] ?? 'Good') as String;
              final negotiable = (data['negotiable'] ?? true) as bool;
              final college = (data['college'] ?? '') as String; // NEW
              final images = (data['images'] ?? []) as List;
              final thumbUrl = images.isNotEmpty
                  ? images.first as String
                  : null;

              return InkWell(
                onTap: () {
                  if (thumbUrl == null) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(
                        categoryName: category,
                        title: productName,
                        description: description,
                        price: price,
                        condition: condition,
                        imageUrl: thumbUrl,
                        isNegotiable: negotiable,
                        college: college, // NEW
                      ),
                    ),
                  );
                },
                child: _ListingTile(
                  productName: productName,
                  description: description,
                  priceText: price > 0 ? '₹ $price' : '',
                  thumbnailUrl: thumbUrl,
                  college: college, // optional to show in list
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ListingTile extends StatelessWidget {
  final String productName;
  final String description;
  final String priceText;
  final String? thumbnailUrl;
  final String college; // NEW

  const _ListingTile({
    required this.productName,
    required this.description,
    required this.priceText,
    this.thumbnailUrl,
    required this.college,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          thumbnailUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    thumbnailUrl!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                )
              : Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  priceText,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (college.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    college,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
