import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class YourListingsScreen extends StatefulWidget {
  const YourListingsScreen({super.key});

  @override
  State<YourListingsScreen> createState() => _YourListingsScreenState();
}

class _YourListingsScreenState extends State<YourListingsScreen> {
  int _selectedTab = 0; // 0 = current, 1 = sold, 2 = expired

  @override
  Widget build(BuildContext context) {
    final app = Firebase.app();
    final db = FirebaseDatabase.instanceFor(
      app: app,
      databaseURL:
          'https://unibazaar-73dd2-default-rtdb.asia-southeast1.firebasedatabase.app',
    );
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('You must be logged in')));
    }

    final query = db.ref('listings').orderByChild('ownerId').equalTo(user.uid);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Your listings',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: query.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading your listings'));
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Listings expire after 7 days, so be sure to renew them.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final raw = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final allEntries = raw.entries.toList()
            ..sort((a, b) {
              final am = a.value as Map;
              final bm = b.value as Map;
              final at = (am['createdAt'] ?? 0) as int;
              final bt = (bm['createdAt'] ?? 0) as int;
              return bt.compareTo(at); // newest first
            });

          final now = DateTime.now();

          final currentEntries = <MapEntry<dynamic, dynamic>>[];
          final soldEntries = <MapEntry<dynamic, dynamic>>[];
          final expiredEntries = <MapEntry<dynamic, dynamic>>[];

          for (final e in allEntries) {
            final m = e.value as Map;
            final status = (m['status'] ?? 'active') as String;
            final int createdAt = (m['createdAt'] ?? 0) as int;
            final expiry = DateTime.fromMillisecondsSinceEpoch(
              createdAt,
            ).add(const Duration(days: 7));

            if (status == 'sold') {
              soldEntries.add(e);
            } else if (expiry.isBefore(now)) {
              expiredEntries.add(e);
            } else {
              currentEntries.add(e);
            }
          }

          List<MapEntry<dynamic, dynamic>> visible;
          bool isSoldTab = false;
          bool isExpiredTab = false;

          if (_selectedTab == 0) {
            visible = currentEntries;
          } else if (_selectedTab == 1) {
            visible = soldEntries;
            isSoldTab = true;
          } else {
            visible = expiredEntries;
            isExpiredTab = true;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  'Listings expire after 7 days, so be sure to renew them.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 8),

              // Tab switcher
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _tabChip('Current', 0),
                    const SizedBox(width: 8),
                    _tabChip('Sold Items', 1),
                    const SizedBox(width: 8),
                    _tabChip('Expired', 2),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final entry = visible[index];
                    return _YourListingTile(
                      id: entry.key as String,
                      data: entry.value as Map<dynamic, dynamic>,
                      db: db,
                      isSold: isSoldTab,
                      isExpired: isExpiredTab,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tabChip(String label, int index) {
    final bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          height: 32,
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.grey.shade300
                : const Color.fromARGB(255, 255, 255, 255),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}

class _YourListingTile extends StatelessWidget {
  final String id;
  final Map<dynamic, dynamic> data;
  final FirebaseDatabase db;
  final bool isSold;
  final bool isExpired;

  const _YourListingTile({
    required this.id,
    required this.data,
    required this.db,
    this.isSold = false,
    this.isExpired = false,
  });

  @override
  Widget build(BuildContext context) {
    final String title = data['productName'] ?? '';
    final double price = (data['price'] as num?)?.toDouble() ?? 0.0;
    final List images = (data['images'] ?? []) as List;
    final String thumbUrl = images.isNotEmpty ? images.first as String : '';

    // CreatedAt and expiry (7 days), rounded up
    final int createdAt = (data['createdAt'] ?? 0) as int;
    final expiry = DateTime.fromMillisecondsSinceEpoch(
      createdAt,
    ).add(const Duration(days: 7));
    final double hoursLeft = expiry
        .difference(DateTime.now())
        .inHours
        .toDouble();
    final int daysLeft = (hoursLeft / 24).ceil().clamp(0, 7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: thumbUrl.isNotEmpty
                    ? Image.network(
                        thumbUrl,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 72,
                        height: 72,
                        color: Colors.grey.shade300,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹ ${price.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 36,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSold
                                    ? Colors.grey.shade300
                                    : const Color(0xFFB7DFA3),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                elevation: 0,
                              ),
                              onPressed: (isSold || isExpired)
                                  ? null
                                  : () async {
                                      await db.ref('listings/$id').update({
                                        'status': 'sold',
                                      });
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Marked as sold'),
                                        ),
                                      );
                                    },
                              child: Text(
                                isSold ? 'Sold' : 'Mark as Sold',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async {
                            await db.ref('listings/$id').remove();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Listing deleted')),
                            );
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.pink.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'Listing expires in $daysLeft days',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(width: 8),
            const Text('|'),
            const SizedBox(width: 8),
            SizedBox(
              height: 28,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: (isSold)
                      ? Colors.grey.shade200
                      : Colors.yellow.shade200,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: isSold
                    ? null
                    : () async {
                        await db.ref('listings/$id').update({
                          'createdAt': DateTime.now().millisecondsSinceEpoch,
                          'status': 'active',
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Listing renewed')),
                        );
                      },
                child: Text(
                  'Renew now',
                  style: TextStyle(
                    fontSize: 13,
                    color: isSold ? Colors.grey : Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
