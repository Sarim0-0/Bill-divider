import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../models/item.dart';
import '../../services/database_service.dart';
import '../../core/theme/app_theme.dart';

class EventItemsScreen extends StatefulWidget {
  final Event event;

  const EventItemsScreen({
    super.key,
    required this.event,
  });

  @override
  State<EventItemsScreen> createState() => _EventItemsScreenState();
}

class _EventItemsScreenState extends State<EventItemsScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Item> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    final items = await _dbService.getItemsByEvent(widget.event.id!);
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  Future<void> _addItem() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Add Item',
          style: TextStyle(
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              style: TextStyle(
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
              ),
              decoration: InputDecoration(
                labelText: 'Item Name',
                labelStyle: TextStyle(
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
                hintText: 'Enter item name',
                hintStyle: TextStyle(
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? AppTheme.darkSurface : AppTheme.lightTextSecondary.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.darkPrimary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: isDark 
                    ? AppTheme.darkBackground 
                    : AppTheme.lightBackground,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
              ),
              decoration: InputDecoration(
                labelText: 'Price',
                labelStyle: TextStyle(
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
                hintText: '0.00',
                hintStyle: TextStyle(
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? AppTheme.darkSurface : AppTheme.lightTextSecondary.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.darkPrimary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: isDark 
                    ? AppTheme.darkBackground 
                    : AppTheme.lightBackground,
                prefixText: 'Rs. ',
                prefixStyle: TextStyle(
                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              final priceText = priceController.text.trim();
              if (name.isNotEmpty && priceText.isNotEmpty) {
                final price = double.tryParse(priceText);
                if (price != null && price >= 0) {
                  Navigator.pop(context, {
                    'name': name,
                    'price': price,
                  });
                }
              }
            },
            child: Text(
              'Add',
              style: TextStyle(
                color: AppTheme.darkPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final item = Item(
          eventId: widget.event.id!,
          name: result['name'],
          price: result['price'],
        );
        await _dbService.insertItem(item);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${result['name']} added successfully'),
              backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
            ),
          );
        }
        _loadItems();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  String _formatPrice(double price) {
    return 'Rs. ${price.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.event.name,
          style: TextStyle(
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppTheme.darkPrimary,
              ),
            )
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.restaurant_menu_outlined,
                        size: 80,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No items added yet',
                        style: TextStyle(
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Items'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.darkSecondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Add Items button in top left
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add_rounded, size: 20),
                          label: const Text('Add Items'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.darkSecondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Items list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              // Item name on the left
                              leading: Text(
                                item.name,
                                style: TextStyle(
                                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                              // Price on the right
                              trailing: Text(
                                _formatPrice(item.price),
                                style: TextStyle(
                                  color: AppTheme.darkPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

