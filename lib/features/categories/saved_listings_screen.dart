import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import 'product_detail_screen.dart';

class SavedListingsScreen extends StatelessWidget {
  const SavedListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('You must be logged in')));
    }

    final app = Firebase.app();
    final db = FirebaseDatabase.instanceFor(
      app: app,
      databaseURL:
          'https://unibazaar-73dd2-default-rtdb.asia-southeast1.firebasedatabase.app',
    );

    final savesRef = db.ref('users/${user.uid}/saves');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved items'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: savesRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading saves'));
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text('No saved listings yet'));
          }

          final savedIdsMap =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final ids = savedIdsMap.keys.cast<String>().toList();

          return StreamBuilder<DatabaseEvent>(
            stream: db.ref('listings').onValue,
            builder: (context, snap2) {
              if (!snap2.hasData || snap2.data!.snapshot.value == null) {
                return const Center(child: Text('No listings found'));
              }

              final raw = snap2.data!.snapshot.value as Map<dynamic, dynamic>;
              final allEntries = raw.entries.toList()
                ..sort((a, b) {
                  final am = a.value as Map;
                  final bm = b.value as Map;
                  final at = (am['createdAt'] ?? 0) as int;
                  final bt = (bm['createdAt'] ?? 0) as int;
                  return bt.compareTo(at);
                });

              final entries = allEntries
                  .where((e) => ids.contains(e.key as String))
                  .toList();

              if (entries.isEmpty) {
                return const Center(child: Text('No saved listings yet'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final id = entries[index].key as String;
                  final data = entries[index].value as Map<dynamic, dynamic>;

                  final productName = (data['productName'] ?? '') as String;
                  final description = (data['description'] ?? '') as String;
                  final price = (data['price'] as num?)?.toDouble() ?? 0.0;
                  final condition = (data['condition'] ?? 'Good') as String;
                  final negotiable = (data['negotiable'] ?? true) as bool;
                  final college = (data['college'] ?? '') as String;
                  final category = (data['category'] ?? '') as String;
                  final sellerUid = (data['sellerUid'] ?? '') as String;
                  final sellerName = (data['sellerName'] ?? '') as String;
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
                            images: images.cast<String>(),
                            isNegotiable: negotiable,
                            college: college,
                            sellerUid: sellerUid,
                            sellerName: sellerName,
                            listingId: id,
                          ),
                        ),
                      );
                    },
                    child: _SavedTile(
                      title: productName,
                      description: description,
                      priceText: price > 0 ? '₹ $price' : '',
                      thumbnailUrl: thumbUrl,
                      college: college,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _SavedTile extends StatelessWidget {
  final String title;
  final String description;
  final String priceText;
  final String? thumbnailUrl;
  final String college;

  const _SavedTile({
    required this.title,
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
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  priceText,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (college.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    college,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
