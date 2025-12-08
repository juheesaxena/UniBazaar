import 'package:flutter/material.dart';

class ProductDetailScreen extends StatelessWidget {
  final String categoryName;
  final String title;
  final String description;
  final double price;
  final String condition;
  final String imageUrl;
  final bool isNegotiable;
  final String college; // NEW

  const ProductDetailScreen({
    super.key,
    required this.categoryName,
    required this.title,
    required this.description,
    required this.price,
    required this.condition,
    required this.imageUrl,
    this.isNegotiable = true,
    this.college = '',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: back + logo only
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    height: 28,
                    child: Image.asset(
                      'assets/images/unibazaar_splash.jpeg',
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Text(
                '$categoryName /',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),

              const SizedBox(height: 12),

              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  height: 260,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(height: 16),

              // TAGS ROW: college and negotiable
              Row(
                children: [
                  if (college.isNotEmpty) _tagChip(college),
                  if (college.isNotEmpty && isNegotiable)
                    const SizedBox(width: 8),
                  if (isNegotiable) _tagChip('Negotiable'),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Price :',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                '₹ ${price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Condition :',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Text(condition, style: const TextStyle(fontSize: 16)),

              const SizedBox(height: 16),

              const Text(
                'Description :',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(description, style: const TextStyle(fontSize: 15)),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB7DFA3),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    // TODO: implement contact seller
                  },
                  child: const Text(
                    'Contact Seller',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tagChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFB7DFA3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
