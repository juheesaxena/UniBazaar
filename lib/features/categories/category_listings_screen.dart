import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import 'product_detail_screen.dart';

class CategoryListingsScreen extends StatefulWidget {
  final String category;

  const CategoryListingsScreen({super.key, required this.category});

  @override
  State<CategoryListingsScreen> createState() => _CategoryListingsScreenState();
}

class _CategoryListingsScreenState extends State<CategoryListingsScreen> {
  String _searchQuery = '';

  // filter state
  double _minPrice = 50;
  double _maxPrice = 50000;
  String _selectedCollege = 'All';

  final List<String> _colleges = const [
    'All',
    'MIT',
    'KMC',
    'MSAP',
    'MSME',
    'TAPMI',
    'DOC',
  ];

  @override
  Widget build(BuildContext context) {
    final app = Firebase.app();
    final db = FirebaseDatabase.instanceFor(
      app: app,
      databaseURL:
          'https://unibazaar-73dd2-default-rtdb.asia-southeast1.firebasedatabase.app',
    );

    // ALWAYS restricted to this category
    final query = db
        .ref('listings')
        .orderByChild('category')
        .equalTo(widget.category);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _openFilterSheet,
          ),
        ],
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
          final allEntries = raw.entries.toList()
            ..sort((a, b) {
              final am = a.value as Map;
              final bm = b.value as Map;
              final at = (am['createdAt'] ?? 0) as int;
              final bt = (bm['createdAt'] ?? 0) as int;
              return bt.compareTo(at); // newest first
            });

          final q = _searchQuery.trim().toLowerCase();

          final entries = allEntries.where((e) {
            final data = e.value as Map<dynamic, dynamic>;

            // hide sold listings
            final status = (data['status'] ?? 'active') as String;
            if (status == 'sold') return false;

            // price filter
            final priceNum = (data['price'] as num?)?.toDouble() ?? 0.0;
            if (priceNum < _minPrice || priceNum > _maxPrice) return false;

            // college filter
            final college = (data['college'] ?? '') as String;
            if (_selectedCollege != 'All' && college != _selectedCollege) {
              return false;
            }

            // search by name / description, still within this category
            if (q.isNotEmpty) {
              final name = (data['productName'] ?? '').toString().toLowerCase();
              final desc = (data['description'] ?? '').toString().toLowerCase();
              if (!name.contains(q) && !desc.contains(q)) return false;
            }

            return true; // already limited to this category by query
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // search bar (category‑only)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search in ${widget.category}',
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                ),
              ),
              if (_searchQuery.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Text(
                    'Showing results for “${_searchQuery.trim()}”',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 4),

              Expanded(
                child: ListView.separated(
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
                    final college = (data['college'] ?? '') as String;

                    // seller info
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
                              categoryName: widget.category,
                              title: productName,
                              description: description,
                              price: price,
                              condition: condition,
                              images: images.cast<String>(),
                              isNegotiable: negotiable,
                              college: college,
                              sellerUid: sellerUid,
                              sellerName: sellerName,
                              listingId: entries[index].key as String,
                            ),
                          ),
                        );
                      },
                      child: _ListingTile(
                        productName: productName,
                        description: description,
                        priceText: price > 0 ? '₹ $price' : '',
                        thumbnailUrl: thumbUrl,
                        college: college,
                      ),
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

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        double tempMin = _minPrice;
        double tempMax = _maxPrice;
        String tempCollege = _selectedCollege;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Price range',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  RangeSlider(
                    min: 50,
                    max: 50000,
                    divisions: 100,
                    labels: RangeLabels(
                      '₹ ${tempMin.toInt()}',
                      '₹ ${tempMax.toInt()}',
                    ),
                    values: RangeValues(tempMin, tempMax),
                    onChanged: (values) {
                      setModalState(() {
                        tempMin = values.start;
                        tempMax = values.end;
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Min: ₹ ${tempMin.toInt()}'),
                      Text('Max: ₹ ${tempMax.toInt()}'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'College',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: tempCollege,
                    items: _colleges
                        .map(
                          (c) => DropdownMenuItem<String>(
                            value: c,
                            child: Text(c),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setModalState(() => tempCollege = value);
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _minPrice = tempMin;
                          _maxPrice = tempMax;
                          _selectedCollege = tempCollege;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Apply filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ListingTile extends StatelessWidget {
  final String productName;
  final String description;
  final String priceText;
  final String? thumbnailUrl;
  final String college;

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
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  productName,
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
