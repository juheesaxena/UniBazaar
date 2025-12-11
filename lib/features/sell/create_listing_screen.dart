import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';

import 'package:unibazaar/services/cloudinary_uploader.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _productNameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  // ⭐ NEW SELLER NAME FIELD
  final _sellerNameCtrl = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _images = [];

  bool _negotiable = true;
  String _condition = 'Brand new';

  String _selectedCategory = 'Electronics';
  final List<String> _categories = [
    'Electronics',
    'Household',
    'Fitness',
    'Beauty',
    'Bicycles',
    'Kitchen',
  ];

  String _selectedCollege = 'MIT';
  final List<String> _colleges = ['MIT', 'KMC', 'MSAP', 'MSME', 'TAPMI', 'DOC'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          'Create listing',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGES
            const Text(
              'Add photos (max 5)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            GestureDetector(
              onTap: () async {
                if (_images.length >= 5) return;

                final XFile? picked = await _picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (picked != null) {
                  setState(() => _images.add(picked));
                }
              },
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: _images.isEmpty
                    ? const Center(
                        child: Icon(Icons.add, size: 32, color: Colors.grey),
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(8),
                        itemCount: _images.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_images[index].path),
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // PRODUCT NAME
            const Text(
              'Product Name',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _productNameCtrl,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),

            // ⭐ NEW SELLER NAME FIELD
            const Text(
              'Seller Name',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _sellerNameCtrl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter your name",
              ),
            ),
            const SizedBox(height: 24),

            // CATEGORY
            const Text(
              'Select Category',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              items: _categories
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedCategory = value!),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),

            // COLLEGE
            const Text(
              'College',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedCollege,
              items: _colleges
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedCollege = value!),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),

            // DESCRIPTION
            const Text(
              'Description',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionCtrl,
              maxLines: 4,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),

            // PRICE
            const Text(
              'Asking Price',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),

            // NEGOTIABLE
            const Text(
              'Negotiable',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            Row(
              children: [
                _buildRadioOption('Yes', true),
                const SizedBox(width: 24),
                _buildRadioOption('No', false),
              ],
            ),
            const SizedBox(height: 24),

            // CONDITION
            const Text(
              'Item Condition',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildConditionChip('Brand new', Colors.green.shade300),
                _buildConditionChip('Excellent', Colors.green.shade200),
                _buildConditionChip('Good', Colors.green.shade100),
                _buildConditionChip('Slightly used', Colors.orange.shade200),
              ],
            ),
            const SizedBox(height: 32),

            // SUBMIT BUTTON
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAEDC98),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('You must be logged in')),
                      );
                      return;
                    }

                    // VALIDATE SELLER NAME
                    if (_sellerNameCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter seller name'),
                        ),
                      );
                      return;
                    }

                    final sellerName = _sellerNameCtrl.text.trim();

                    final price = double.tryParse(_priceCtrl.text.trim());
                    if (price == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid price')),
                      );
                      return;
                    }

                    final db = FirebaseDatabase.instanceFor(
                      app: Firebase.app(),
                      databaseURL:
                          'https://unibazaar-73dd2-default-rtdb.asia-southeast1.firebasedatabase.app',
                    );

                    final ref = db.ref('listings').push();

                    // upload images
                    final uploader = const CloudinaryUploader();
                    final List<String> urls = [];
                    for (final img in _images) {
                      urls.add(await uploader.uploadImage(File(img.path)));
                    }

                    // WRITE DATA WITH SELLER NAME FIELD
                    await ref.set({
                      'productName': _productNameCtrl.text.trim(),
                      'description': _descriptionCtrl.text.trim(),
                      'price': price,
                      'negotiable': _negotiable,
                      'condition': _condition,
                      'category': _selectedCategory,
                      'college': _selectedCollege,

                      /// ⭐ ADDED FIELD HERE
                      'sellerName': sellerName,
                      'sellerUid': user.uid,

                      'ownerId': user.uid,
                      'ownerPhone': user.phoneNumber ?? '',
                      'createdAt': DateTime.now().millisecondsSinceEpoch,
                      'images': urls,
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Listing created')),
                    );
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: const Text(
                  'Sell your Item',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption(String label, bool value) {
    return Row(
      children: [
        Radio<bool>(
          value: value,
          groupValue: _negotiable,
          onChanged: (v) => setState(() => _negotiable = v!),
        ),
        Text(label),
      ],
    );
  }

  Widget _buildConditionChip(String label, Color color) {
    final selected = _condition == label;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: color,
      onSelected: (_) => setState(() => _condition = label),
    );
  }
}
