import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size; // for responsiveness

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.04, // 4% of width
            vertical: size.height * 0.015, // 1.5% of height
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.menu, size: 22),
                  ),
                  Row(
                    children: const [
                      Text(
                        "UNI",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        "BAZAAR",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade200,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade200,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "A",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: size.height * 0.02),

              const Text(
                "All Listings",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: size.height * 0.015),

              // List takes remaining height
              Expanded(
                child: StreamBuilder<DatabaseEvent>(
                  stream: FirebaseDatabase.instance.ref('listings').onValue,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Error loading listings'),
                      );
                    }
                    if (!snapshot.hasData ||
                        snapshot.data!.snapshot.value == null) {
                      return const Center(child: Text('No listings yet'));
                    }

                    final raw =
                        snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                    final entries = raw.entries.toList()
                      ..sort((a, b) {
                        final am = a.value as Map;
                        final bm = b.value as Map;
                        final at = (am['createdAt'] ?? 0) as int;
                        final bt = (bm['createdAt'] ?? 0) as int;
                        return bt.compareTo(at); // newest first
                      });

                    return ListView.separated(
                      itemCount: entries.length,
                      separatorBuilder: (_, __) =>
                          SizedBox(height: size.height * 0.012),
                      itemBuilder: (context, index) {
                        final listing =
                            entries[index].value as Map<dynamic, dynamic>;
                        final description =
                            (listing['description'] ?? '') as String;
                        final price = listing['price'];

                        final images = (listing['images'] ?? []) as List;
                        final thumbUrl = images.isNotEmpty
                            ? images.first as String
                            : null;

                        return ListingCard(
                          description: description,
                          priceText: price != null ? '$price' : '',
                          thumbnailUrl: thumbUrl,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ListingCard extends StatelessWidget {
  final String description;
  final String priceText;
  final String? thumbnailUrl;

  const ListingCard({
    super.key,
    required this.description,
    required this.priceText,
    this.thumbnailUrl,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      padding: EdgeInsets.all(size.width * 0.03),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Responsive image (Cloudinary/Firebase URL) or placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: thumbnailUrl != null
                ? Image.network(
                    thumbnailUrl!,
                    width: size.width * 0.2,
                    height: size.width * 0.2,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: size.width * 0.2,
                    height: size.width * 0.2,
                    color: Colors.grey.shade300,
                  ),
          ),
          SizedBox(width: size.width * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  '₹ $priceText',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
