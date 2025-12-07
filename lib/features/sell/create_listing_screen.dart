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
            // PHOTOS
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
                  setState(() {
                    _images.add(picked);
                  });
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

            // CATEGORY
            const Text(
              'Select Category',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: _categories
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
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
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // NEGOTIABLE
            const Text(
              'Negotiable',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
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
            const SizedBox(height: 8),
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
                  print('BUTTON PRESSED');

                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    print('USER: $user');

                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('You must be logged in')),
                      );
                      return;
                    }

                    final productName = _productNameCtrl.text.trim();
                    final description = _descriptionCtrl.text.trim();
                    final priceText = _priceCtrl.text.trim();

                    print(
                      'DATA: $productName | $description | $priceText | $_selectedCategory',
                    );

                    if (productName.isEmpty ||
                        description.isEmpty ||
                        priceText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields')),
                      );
                      return;
                    }

                    final price = double.tryParse(priceText);
                    if (price == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid price')),
                      );
                      return;
                    }

                    final ownerPhone = user.phoneNumber ?? '';

                    // Realtime DB (keep)
                    final firebaseApp = Firebase.app();
                    final db = FirebaseDatabase.instanceFor(
                      app: firebaseApp,
                      databaseURL:
                          'https://unibazaar-73dd2-default-rtdb.asia-southeast1.firebasedatabase.app',
                    );
                    final ref = db.ref('listings').push();
                    print('REF PATH: ${ref.path}');

                    // Upload images to Cloudinary (new)
                    final uploader = const CloudinaryUploader();
                    final List<String> imageUrls = [];
                    for (int i = 0; i < _images.length; i++) {
                      final file = File(_images[i].path);
                      final url = await uploader.uploadImage(file);
                      imageUrls.add(url);
                    }

                    // Save listing + Cloudinary URLs
                    await ref.set({
                      'productName': productName,
                      'description': description,
                      'price': price,
                      'negotiable': _negotiable,
                      'condition': _condition,
                      'category': _selectedCategory,
                      'ownerId': user.uid,
                      'ownerPhone': ownerPhone,
                      'createdAt': DateTime.now().millisecondsSinceEpoch,
                      'images': imageUrls,
                    });

                    print('WRITE OK');

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Listing created')),
                    );

                    _productNameCtrl.clear();
                    _descriptionCtrl.clear();
                    _priceCtrl.clear();
                    _images.clear();

                    Navigator.pop(context);
                  } catch (e, st) {
                    print('WRITE ERROR: $e');
                    print(st);
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<bool>(
          value: value,
          groupValue: _negotiable,
          onChanged: (v) {
            if (v != null) setState(() => _negotiable = v);
          },
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
      backgroundColor: Colors.grey.shade200,
      onSelected: (_) {
        setState(() => _condition = label);
      },
      labelStyle: TextStyle(
        color: Colors.black,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
