import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';

import '../models/business_card.dart';
import '../data/database_helper.dart';
import '../services/text_recognition_service.dart';
import 'card_detail_screen.dart';
import 'map_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../widgets/business_card_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<BusinessCard> _cards = [];
  List<BusinessCard> _filteredCards = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  int _currentIndex = 0; // 0: Home, 1: Favorites, 2: Map
  final TextRecognitionService _recognitionService = TextRecognitionService();

  // Selection Mode State
  bool _isSelectionMode = false;
  final Set<String> _selectedCardIds = {};

  Timer? _refreshTimer; // Add timer variable

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    await DatabaseHelper.instance.seedDataIfEmpty();
    await _refreshCards();
  }

  Future<void> _refreshCards() async {
    final cards = await DatabaseHelper.instance.readAllCards();
    setState(() {
      _cards = cards;
      _filterCards();
      _isLoading = false;
    });
  }

  void _filterCards() {
    setState(() {
      _filteredCards = _cards.where((card) {
        final matchesSearch =
            card.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            card.company.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesCategory =
            _selectedCategory == 'All' || card.category == _selectedCategory;

        // Tab filtering
        if (_currentIndex == 1) {
          // Favorites
          return matchesSearch && matchesCategory && card.isFavorite;
        }

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  Future<void> _scanCard() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final card = await _recognitionService.processImage(pickedFile.path);
        if (!mounted) return;
        Navigator.pop(context);

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CardDetailScreen(card: card, isNew: true),
          ),
        );

        if (result == true) {
          _refreshCards();
          // Schedule a refresh in 3 seconds to catch background geocoding completion
          _refreshTimer?.cancel();
          _refreshTimer = Timer(const Duration(seconds: 3), () {
            if (mounted) _refreshCards();
          });
        }
      } catch (e) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _toggleFavorite(BusinessCard card) async {
    final updatedCard = card.copyWith(isFavorite: !card.isFavorite);
    await DatabaseHelper.instance.updateCard(updatedCard);
    _refreshCards();
  }

  void _showQrDialog(BusinessCard card) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Text(
                card.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                card.company,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: QrImageView(
                    data:
                        'BEGIN:VCARD\nVERSION:3.0\nN:${card.name}\nORG:${card.company}\nTEL:${card.phone}\nEMAIL:${card.email}\nURL:${card.website}\nADR:;;${card.address};;;;\nEND:VCARD',
                    version: QrVersions.auto,
                    size: 220,
                    gapless: false,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Colors.black,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Scan to add contact',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // Selection Mode Methods
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedCardIds.clear();
    });
  }

  void _toggleCardSelection(String cardId) {
    setState(() {
      if (_selectedCardIds.contains(cardId)) {
        _selectedCardIds.remove(cardId);
      } else {
        _selectedCardIds.add(cardId);
      }
    });
  }

  Future<void> _deleteSelectedCards() async {
    if (_selectedCardIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Cards'),
        content: Text(
          'Are you sure you want to delete ${_selectedCardIds.length} card(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteCards(_selectedCardIds.toList());
      setState(() {
        _isSelectionMode = false;
        _selectedCardIds.clear();
      });
      _refreshCards();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _currentIndex == 2
          ? null
          : AppBar(
              title: Text(
                _currentIndex == 1 ? 'Favorites' : 'Card Holder',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Theme.of(context).colorScheme.surface,
              elevation: 0,
              actions: _buildAppBarActions(),
            ),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) async {
          if (_isSelectionMode) {
            _toggleSelectionMode(); // Exit selection mode on tab switch
          }

          setState(() {
            _currentIndex = index;
            // Optionally show loading if switching to map or list
          });

          // Refresh data to ensure map sees latest background updates
          await _refreshCards();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.style_outlined),
            selectedIcon: Icon(Icons.style),
            label: 'Cards',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
        ],
      ),
      floatingActionButton: (_currentIndex == 2 || _isSelectionMode)
          ? null
          : FloatingActionButton.extended(
              onPressed: _scanCard,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scan'),
            ),
    );
  }

  List<Widget> _buildAppBarActions() {
    if (_isSelectionMode) {
      return [
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: _selectedCardIds.isNotEmpty ? _deleteSelectedCards : null,
          tooltip: 'Delete Selected',
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: _toggleSelectionMode,
          tooltip: 'Cancel',
        ),
        const SizedBox(width: 8),
      ];
    }

    return [
      IconButton(
        icon: const Icon(Icons.edit),
        onPressed: _toggleSelectionMode,
        tooltip: 'Edit',
      ),
      IconButton(
        icon: const Icon(Icons.settings_outlined),
        tooltip: 'Settings',
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings not implemented yet')),
          );
        },
      ),
      const SizedBox(width: 8),
    ];
  }

  Widget _buildBody() {
    if (_currentIndex == 2) {
      return MapScreen(
        cards: _cards, // Pass all cards, not just filtered
        onLocationsUpdated: _refreshCards,
      );
    }

    return Column(
      children: [
        if (_currentIndex != 2) _buildSearchBar(),
        if (_currentIndex != 2) _buildFilterChips(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredCards.isEmpty
              ? _buildEmptyState()
              : _buildGrid(),
        ),
      ],
    );
  }

  // ... _buildSearchBar and _buildFilterChips remain same ...

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search cards...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade200,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 0,
          ),
        ),
        onChanged: (val) {
          _searchQuery = val;
          _filterCards();
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    final categories = [
      'All',
      'Tech',
      'Finance',
      'Creative',
      'Services',
      'Uncategorized',
    ];
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = cat;
                  _filterCards();
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.credit_card_off, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No cards found here.',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1, // Full width cards for impact
        childAspectRatio: 1.8, // Business card ratio-ish
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredCards.length,
      itemBuilder: (context, index) {
        final card = _filteredCards[index];
        final isSelected = _selectedCardIds.contains(card.id);

        return BusinessCardWidget(
          card: card,
          isSelectionMode: _isSelectionMode,
          isSelected: isSelected,
          onTap: () async {
            if (_isSelectionMode) {
              _toggleCardSelection(card.id);
            } else {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CardDetailScreen(card: card),
                ),
              );
              if (result == true) {
                _refreshCards();
                // Schedule a refresh to catch background updates
                _refreshTimer?.cancel();
                _refreshTimer = Timer(const Duration(seconds: 3), () {
                  if (mounted) _refreshCards();
                });
              }
            }
          },
          onFavoriteToggle: () => _toggleFavorite(card),
          onQrTap: () => _showQrDialog(card),
        );
      },
    );
  }
}
