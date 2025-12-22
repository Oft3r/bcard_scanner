import 'dart:io';
import 'package:flutter/material.dart';
import '../models/business_card.dart';
import '../data/database_helper.dart';
import '../services/geocoding_service.dart';

class CardDetailScreen extends StatefulWidget {
  final BusinessCard card;
  final bool isNew;

  const CardDetailScreen({super.key, required this.card, this.isNew = false});

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  late TextEditingController _nameController;
  late TextEditingController _titleController;
  late TextEditingController _companyController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  late TextEditingController _addressController;
  String _category = 'Uncategorized';
  bool _isLoading = false;

  final List<String> _categories = [
    'Uncategorized',
    'Tech',
    'Finance',
    'Creative',
    'Services',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.card.name);
    _titleController = TextEditingController(text: widget.card.title);
    _companyController = TextEditingController(text: widget.card.company);
    _phoneController = TextEditingController(text: widget.card.phone);
    _emailController = TextEditingController(text: widget.card.email);
    _websiteController = TextEditingController(text: widget.card.website);
    _addressController = TextEditingController(text: widget.card.address);
    _category = widget.card.category;
    if (!_categories.contains(_category)) {
      _categories.add(_category);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'New Card' : 'Edit Card'),
        actions: [
          if (!widget.isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _deleteCard,
            ),
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check),
            onPressed: _isLoading ? null : _saveCard,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.card.imagePath.isNotEmpty)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: FileImage(File(widget.card.imagePath)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            _buildTextField(_nameController, 'Name', Icons.person),
            const SizedBox(height: 12),
            _buildTextField(_titleController, 'Job Title', Icons.work),
            const SizedBox(height: 12),
            _buildTextField(_companyController, 'Company', Icons.business),
            const SizedBox(height: 12),
            _buildTextField(
              _phoneController,
              'Phone',
              Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              _emailController,
              'Email',
              Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            _buildTextField(_websiteController, 'Website', Icons.language),
            const SizedBox(height: 12),
            _buildTextField(_addressController, 'Address', Icons.location_on),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: InputDecoration(
                labelText: 'Category',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) => setState(() => _category = val!),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }

  void _saveCard() async {
    setState(() => _isLoading = true);

    try {
      final String newAddress = _addressController.text.trim();
      final bool addressChanged = newAddress != widget.card.address;

      // 1. Prepare card for immediate save.
      // If address changed, temporarily clear coordinates.
      // If address didn't change, keep existing coordinates.
      final double? initialLat = addressChanged ? null : widget.card.latitude;
      final double? initialLng = addressChanged ? null : widget.card.longitude;

      final cardToSave = BusinessCard(
        id: widget.card.id,
        name: _nameController.text,
        title: _titleController.text,
        company: _companyController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        website: _websiteController.text,
        address: newAddress,
        imagePath: widget.card.imagePath,
        category: _category,
        scanDate: widget.card.scanDate,
        isFavorite: widget.card.isFavorite,
        latitude: initialLat,
        longitude: initialLng,
        colorIndex: widget.card.colorIndex,
      );

      // 2. Save to Database immediately
      if (widget.isNew) {
        await DatabaseHelper.instance.createCard(cardToSave);
      } else {
        await DatabaseHelper.instance.updateCard(cardToSave);
      }

      // 3. Close screen immediately
      if (mounted) Navigator.pop(context, true);

      // 4. Trigger Background Geocoding if needed
      // (Address changed OR coordinates are missing but we have an address)
      if (newAddress.isNotEmpty && (addressChanged || initialLat == null)) {
        _runBackgroundGeocoding(cardToSave);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving card: $e')));
      }
    }
  }

  void _runBackgroundGeocoding(BusinessCard card) async {
    // Fire and forget - doesn't block UI
    if (card.address.isEmpty) {
      debugPrint(
        'Background Geocoding: Skipping ${card.name} - no address provided',
      );
      return;
    }

    try {
      debugPrint('=== GEOCODING START ===');
      debugPrint('Contact: ${card.name}');
      debugPrint('Raw Address: "${card.address}"');

      final coords = await GeocodingService().getCoordinates(card.address);

      if (coords != null) {
        debugPrint('=== GEOCODING SUCCESS ===');
        debugPrint('Lat: ${coords['latitude']}, Lng: ${coords['longitude']}');

        final updatedCard = BusinessCard(
          id: card.id,
          name: card.name,
          title: card.title,
          company: card.company,
          phone: card.phone,
          email: card.email,
          website: card.website,
          address: card.address,
          imagePath: card.imagePath,
          category: card.category,
          scanDate: card.scanDate,
          isFavorite: card.isFavorite,
          latitude: coords['latitude'],
          longitude: coords['longitude'],
          colorIndex: card.colorIndex,
        );
        await DatabaseHelper.instance.updateCard(updatedCard);
        debugPrint('Database updated for ${card.name}');
      } else {
        debugPrint('=== GEOCODING FAILED ===');
        debugPrint('Could not resolve any coordinates for: "${card.address}"');
        debugPrint('The contact "${card.name}" will NOT appear on the map.');
      }
    } catch (e, stackTrace) {
      debugPrint('=== GEOCODING ERROR ===');
      debugPrint('Error: $e');
      debugPrint('Stack: $stackTrace');
    }
  }

  Future<void> _deleteCard() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Card?'),
        content: const Text(
          'Are you sure you want to delete this business card? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteCard(widget.card.id);
      if (mounted) Navigator.pop(context, true);
    }
  }
}
