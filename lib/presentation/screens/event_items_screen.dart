import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../models/item.dart';
import '../../models/variant.dart';
import '../../models/add_on.dart';
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

  static String formatPrice(double price) {
    return 'Rs. ${price.toStringAsFixed(2)}';
  }

  /// Calculate the final price for an item (base price + variant + add-ons)
  Future<double> _calculateItemPrice(Item item) async {
    // Start with base price
    double basePrice = item.price;
    
    // Check if there's a variant selection (replaces base price)
    final variantSelection = await _dbService.getItemVariantWithDetails(item.id!);
    if (variantSelection != null) {
      basePrice = (variantSelection['variant_price'] as num).toDouble();
    }
    
    // Add add-ons (add to price)
    final addOnSelections = await _dbService.getItemAddOnsWithDetails(item.id!);
    double addOnTotal = 0.0;
    for (var addOn in addOnSelections) {
      final addOnPrice = (addOn['addon_price'] as num).toDouble();
      final quantity = addOn['quantity'] as int;
      addOnTotal += addOnPrice * quantity;
    }
    
    return basePrice + addOnTotal;
  }

  Future<void> _showItemDetails(Item item) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Load variant and add-on selections
    final variantSelection = await _dbService.getItemVariantWithDetails(item.id!);
    final addOnSelections = await _dbService.getItemAddOnsWithDetails(item.id!);
    
    // Calculate base price (variant replaces base price, add-ons add to it)
    double basePrice = item.price;
    if (variantSelection != null) {
      basePrice = (variantSelection['variant_price'] as num).toDouble();
    }
    
    // Calculate add-on total
    double addOnTotal = 0.0;
    for (var addOn in addOnSelections) {
      final addOnPrice = (addOn['addon_price'] as num).toDouble();
      final quantity = addOn['quantity'] as int;
      addOnTotal += addOnPrice * quantity;
    }
    
    // Calculate final price (base + add-ons)
    double finalPrice = basePrice + addOnTotal;
    
    // State for dialog
    int quantity = 1;
    
    try {
      await showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              item.name,
              style: TextStyle(
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Base price display (read-only)
                  Text(
                    'Base Price',
                    style: TextStyle(
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppTheme.darkSurface : AppTheme.lightTextSecondary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          variantSelection != null 
                              ? 'Variant: ${variantSelection['variant_name']}'
                              : 'Base Item',
                          style: TextStyle(
                            color: isDark ? AppTheme.darkText : AppTheme.lightText,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _formatPrice(basePrice),
                          style: TextStyle(
                            color: AppTheme.darkPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Summary box
                  if (variantSelection != null || addOnSelections.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.darkPrimary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Summary',
                            style: TextStyle(
                              color: isDark ? AppTheme.darkText : AppTheme.lightText,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (variantSelection != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                'Variant: ${variantSelection['variant_name']} (${_formatPrice((variantSelection['variant_price'] as num).toDouble())})',
                                style: TextStyle(
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          if (addOnSelections.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                'Add-ons: ${addOnSelections.length} added',
                                style: TextStyle(
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          if (addOnSelections.isNotEmpty)
                            ...addOnSelections.map((addOn) => Padding(
                              padding: const EdgeInsets.only(left: 8, top: 2),
                              child: Text(
                                '  • ${addOn['addon_name']} x${addOn['quantity']} (${_formatPrice((addOn['addon_price'] as num).toDouble() * (addOn['quantity'] as int))})',
                                style: TextStyle(
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            )).toList(),
                        ],
                      ),
                    ),
                  if (variantSelection != null || addOnSelections.isNotEmpty)
                    const SizedBox(height: 16),
                  // Quantity controls
                  Text(
                    'Quantity',
                    style: TextStyle(
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (quantity > 1) {
                            setDialogState(() {
                              quantity--;
                            });
                          }
                        },
                        icon: Icon(
                          Icons.remove_circle_outline,
                          color: quantity > 1 
                              ? AppTheme.darkPrimary 
                              : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                        ),
                        iconSize: 32,
                      ),
                      Container(
                        width: 60,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppTheme.darkSurface : AppTheme.lightTextSecondary.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          quantity.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? AppTheme.darkText : AppTheme.lightText,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setDialogState(() {
                            quantity++;
                          });
                        },
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: AppTheme.darkPrimary,
                        ),
                        iconSize: 32,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Total price (calculated from finalPrice * quantity)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total:',
                          style: TextStyle(
                            color: isDark ? AppTheme.darkText : AppTheme.lightText,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _formatPrice(finalPrice * quantity),
                          style: TextStyle(
                            color: AppTheme.darkPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Variant and Add-ons buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final result = await _showVariantsDialog(item);
                            if (result == true && mounted) {
                              // Reload the dialog with updated data
                              Navigator.of(context).pop();
                              _showItemDetails(item);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                            foregroundColor: isDark ? AppTheme.darkText : AppTheme.lightText,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary.withOpacity(0.3),
                              ),
                            ),
                          ),
                          child: const Text('Variant'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final result = await _showAddOnsDialog(item);
                            if (result == true && mounted) {
                              // Reload the dialog with updated data
                              Navigator.of(context).pop();
                              _showItemDetails(item);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                            foregroundColor: isDark ? AppTheme.darkText : AppTheme.lightText,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary.withOpacity(0.3),
                              ),
                            ),
                          ),
                          child: const Text('Add-ons'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: TextStyle(
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      // Handle any errors
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

  Future<bool?> _showVariantsDialog(Item item) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => _VariantsDialog(
        item: item,
        isDark: isDark,
        dbService: _dbService,
      ),
    );
  }

  Future<bool?> _showAddOnsDialog(Item item) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => _AddOnsDialog(
        item: item,
        isDark: isDark,
        dbService: _dbService,
      ),
    );
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
                              // Price on the right - show calculated price
                              trailing: FutureBuilder<double>(
                                future: _calculateItemPrice(item),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    );
                                  }
                                  final calculatedPrice = snapshot.data ?? item.price;
                                  return Text(
                                    _formatPrice(calculatedPrice),
                                    style: TextStyle(
                                      color: AppTheme.darkPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                              onTap: () {
                                _showItemDetails(item);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildVariantAddOnItem(
    BuildContext context,
    bool isDark,
    String name,
    double price,
    int quantity,
    Function(int) onQuantityChanged,
    VoidCallback onEditPrice,
  ) {
    return _buildVariantAddOnItemWidget(
      context,
      isDark,
      name,
      price,
      quantity,
      onQuantityChanged,
      onEditPrice,
    );
  }

  static Widget _buildVariantAddOnItemWidget(
    BuildContext context,
    bool isDark,
    String name,
    double price,
    int quantity,
    Function(int) onQuantityChanged,
    VoidCallback onEditPrice,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: quantity > 0 
              ? AppTheme.darkPrimary 
              : (isDark ? AppTheme.darkSurface : AppTheme.lightTextSecondary.withOpacity(0.3)),
          width: quantity > 0 ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
            TextButton(
              onPressed: onEditPrice,
              child: Text(
                _EventItemsScreenState.formatPrice(price),
                style: TextStyle(
                  color: AppTheme.darkPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: quantity > 0
                  ? () => onQuantityChanged(quantity - 1)
                  : null,
              icon: Icon(
                Icons.remove_circle_outline,
                color: quantity > 0
                    ? AppTheme.darkPrimary
                    : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
              ),
              iconSize: 28,
            ),
            Container(
              width: 50,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                quantity.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              onPressed: () => onQuantityChanged(quantity + 1),
              icon: Icon(
                Icons.add_circle_outline,
                color: AppTheme.darkPrimary,
              ),
              iconSize: 28,
            ),
          ],
        ),
      ),
    );
  }
}

// Helper class to track added variants
class _AddedVariant {
  final Variant variant;
  final String name;
  final double price;
  final int quantity;

  _AddedVariant({
    required this.variant,
    required this.name,
    required this.price,
    required this.quantity,
  });
}

// Helper class to track added add-ons
class _AddedAddOn {
  final AddOn addOn;
  final String name;
  final double price;
  final int quantity;

  _AddedAddOn({
    required this.addOn,
    required this.name,
    required this.price,
    required this.quantity,
  });
}

class _VariantsDialog extends StatefulWidget {
  final Item item;
  final bool isDark;
  final DatabaseService dbService;

  const _VariantsDialog({
    required this.item,
    required this.isDark,
    required this.dbService,
  });

  @override
  State<_VariantsDialog> createState() => _VariantsDialogState();
}

class _VariantsDialogState extends State<_VariantsDialog> {
  // Map to track added variants and their quantities
  Map<int, _AddedVariant> addedVariants = {}; // variantId -> AddedVariant
  late Future<List<Variant>> _variantsFuture;

  @override
  void initState() {
    super.initState();
    _variantsFuture = widget.dbService.getVariantsByItem(widget.item.id!);
    _loadExistingSelections();
  }

  void _loadExistingSelections() async {
    // Load existing variant selection for this item
    final variantSelection = await widget.dbService.getItemVariantWithDetails(widget.item.id!);
    if (variantSelection != null) {
      setState(() {
        addedVariants[variantSelection['variant_id']] = _AddedVariant(
          variant: Variant(
            id: variantSelection['variant_id'],
            itemId: widget.item.id!,
            name: variantSelection['variant_name'],
            price: (variantSelection['variant_price'] as num).toDouble(),
          ),
          name: variantSelection['variant_name'],
          price: (variantSelection['variant_price'] as num).toDouble(),
          quantity: variantSelection['quantity'],
        );
      });
    }
  }

  void _refreshVariants() {
    setState(() {
      _variantsFuture = widget.dbService.getVariantsByItem(widget.item.id!);
    });
  }

  Future<void> _showVariantQuantityDialog(Variant variant) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    double currentPrice = variant.price;
    int quantity = 1;
    final nameController = TextEditingController(text: variant.name);
    final priceController = TextEditingController(text: currentPrice.toStringAsFixed(2));
    
    await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Add Variant',
            style: TextStyle(
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  'Name',
                  style: TextStyle(
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  style: TextStyle(
                    color: isDark ? AppTheme.darkText : AppTheme.lightText,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Variant name',
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
                    fillColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                  ),
                ),
                const SizedBox(height: 16),
                // Price
                Text(
                  'Price',
                  style: TextStyle(
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    color: isDark ? AppTheme.darkText : AppTheme.lightText,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
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
                    fillColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                    prefixText: 'Rs. ',
                    prefixStyle: TextStyle(
                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                    ),
                  ),
                  onChanged: (value) {
                    final price = double.tryParse(value);
                    if (price != null && price >= 0) {
                      setDialogState(() {
                        currentPrice = price;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),
                // Quantity
                Text(
                  'Quantity',
                  style: TextStyle(
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        if (quantity > 1) {
                          setDialogState(() {
                            quantity--;
                          });
                        }
                      },
                      icon: Icon(
                        Icons.remove_circle_outline,
                        color: quantity > 1
                            ? AppTheme.darkPrimary
                            : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                      ),
                      iconSize: 32,
                    ),
                    Container(
                      width: 60,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppTheme.darkSurface : AppTheme.lightTextSecondary.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        quantity.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? AppTheme.darkText : AppTheme.lightText,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setDialogState(() {
                          quantity++;
                        });
                      },
                      icon: Icon(
                        Icons.add_circle_outline,
                        color: AppTheme.darkPrimary,
                      ),
                      iconSize: 32,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Total price
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total:',
                        style: TextStyle(
                          color: isDark ? AppTheme.darkText : AppTheme.lightText,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _EventItemsScreenState.formatPrice(currentPrice * quantity),
                        style: TextStyle(
                          color: AppTheme.darkPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
                final finalPrice = double.tryParse(priceText);
                
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Please enter a name'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                
                if (finalPrice == null || finalPrice < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Please enter a valid price'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                
                Navigator.pop(context);
                // Add to added variants (replaces any existing variant since only one is allowed)
                setState(() {
                  addedVariants.clear(); // Clear existing variants
                  addedVariants[variant.id!] = _AddedVariant(
                    variant: variant,
                    name: name,
                    price: finalPrice,
                    quantity: quantity,
                  );
                });
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
      ),
    );
    
    nameController.dispose();
    priceController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: widget.isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 700, maxWidth: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Variants for ${widget.item.name}',
                    style: TextStyle(
                      color: widget.isDark ? AppTheme.darkText : AppTheme.lightText,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: widget.isDark ? AppTheme.darkText : AppTheme.lightText,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Two sections
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Available section
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.isDark ? AppTheme.darkSurface : AppTheme.lightTextSecondary.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Available',
                                  style: TextStyle(
                                    color: widget.isDark ? AppTheme.darkText : AppTheme.lightText,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_rounded),
                                  color: AppTheme.darkPrimary,
                                  onPressed: () => _addVariant(),
                                  tooltip: 'Add Variant',
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: FutureBuilder<List<Variant>>(
                              future: _variantsFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                
                                if (snapshot.hasError) {
                                  return Center(
                                    child: Text(
                                      'Error loading variants: ${snapshot.error}',
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  );
                                }
                                
                                final variants = snapshot.data ?? [];
                                // Show all variants in available (don't filter out added ones)
                                final availableVariants = variants;
                                
                                if (availableVariants.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.category_outlined,
                                          size: 60,
                                          color: widget.isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No variants available',
                                          style: TextStyle(
                                            color: widget.isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                
                                return ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  itemCount: availableVariants.length,
                                  itemBuilder: (context, index) {
                                    final variant = availableVariants[index];
                                    return _buildAvailableVariantCard(variant);
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Added section
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.isDark ? AppTheme.darkSurface : AppTheme.lightTextSecondary.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Added',
                              style: TextStyle(
                                color: widget.isDark ? AppTheme.darkText : AppTheme.lightText,
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          Expanded(
                            child: addedVariants.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.shopping_cart_outlined,
                                          size: 60,
                                          color: widget.isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No variants added',
                                          style: TextStyle(
                                            color: widget.isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    itemCount: addedVariants.length,
                                    itemBuilder: (context, index) {
                                      final addedVariant = addedVariants.values.toList()[index];
                                      return _buildAddedVariantCard(addedVariant);
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Confirm button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: widget.isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      // Save selections to database
                      if (addedVariants.isEmpty) {
                        // Remove variant selection if no variants are added
                        await widget.dbService.deleteItemVariantSelection(widget.item.id!);
                      } else {
                        // Save the first (and only) variant selection
                        final addedVariant = addedVariants.values.first;
                        await widget.dbService.saveItemVariantSelection(
                          widget.item.id!,
                          addedVariant.variant.id!,
                          addedVariant.quantity,
                        );
                      }
                      Navigator.pop(context, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.darkPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Confirm'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableVariantCard(Variant variant) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: widget.isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      child: ListTile(
        title: Text(
          variant.name,
          style: TextStyle(
            color: widget.isDark ? AppTheme.darkText : AppTheme.lightText,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Text(
          _EventItemsScreenState.formatPrice(variant.price),
          style: TextStyle(
            color: AppTheme.darkPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        onTap: () => _showVariantQuantityDialog(variant),
      ),
    );
  }

  Widget _buildAddedVariantCard(_AddedVariant addedVariant) {
    final totalPrice = addedVariant.price * addedVariant.quantity;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: widget.isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      child: ListTile(
        title: Text(
          addedVariant.name,
          style: TextStyle(
            color: widget.isDark ? AppTheme.darkText : AppTheme.lightText,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${addedVariant.quantity}x ',
              style: TextStyle(
                color: widget.isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                fontSize: 14,
              ),
            ),
            Text(
              _EventItemsScreenState.formatPrice(totalPrice),
              style: TextStyle(
                color: AppTheme.darkPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 20,
              ),
              onPressed: () {
                // Remove from added
                setState(() {
                  addedVariants.remove(addedVariant.variant.id);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addVariant() async {
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
          'Add Variant',
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
                labelText: 'Variant Name',
                labelStyle: TextStyle(
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
                hintText: 'Enter variant name',
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
                fillColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
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
                hintText: '0.00',
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
                fillColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
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
        final variant = Variant(
          itemId: widget.item.id!,
          name: result['name'],
          price: result['price'],
        );
        await widget.dbService.insertVariant(variant);
        _refreshVariants();
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
    
    nameController.dispose();
    priceController.dispose();
  }

  Future<void> _editVariantPrice(Variant variant) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final priceController = TextEditingController(text: variant.price.toStringAsFixed(2));

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Edit ${variant.name} Price',
          style: TextStyle(
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: priceController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
          ),
          decoration: InputDecoration(
            labelText: 'Price',
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
            fillColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
            prefixText: 'Rs. ',
            prefixStyle: TextStyle(
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
            ),
          ),
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
            onPressed: () async {
              final priceText = priceController.text.trim();
              final newPrice = double.tryParse(priceText);
              
              if (newPrice != null && newPrice >= 0 && newPrice != variant.price) {
                try {
                  await widget.dbService.updateVariantPriceForPresentAndFuture(
                    widget.item.id!,
                    variant.name,
                    newPrice,
                  );
                  _refreshVariants();
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Price updated for ${variant.name}'),
                        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
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
              } else {
                Navigator.pop(context);
              }
            },
            child: Text(
              'Save',
              style: TextStyle(
                color: AppTheme.darkPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    
    priceController.dispose();
  }
}

class _AddOnsDialog extends StatefulWidget {
  final Item item;
  final bool isDark;
  final DatabaseService dbService;

  const _AddOnsDialog({
    required this.item,
    required this.isDark,
    required this.dbService,
  });

  @override
  State<_AddOnsDialog> createState() => _AddOnsDialogState();
}

class _AddOnsDialogState extends State<_AddOnsDialog> {
  // Map to track added add-ons and their quantities
  Map<int, _AddedAddOn> addedAddOns = {}; // addOnId -> AddedAddOn
  late Future<List<AddOn>> _addOnsFuture;

  @override
  void initState() {
    super.initState();
    _addOnsFuture = widget.dbService.getAddOnsByItem(widget.item.id!);
  }

  void _refreshAddOns() {
    setState(() {
      _addOnsFuture = widget.dbService.getAddOnsByItem(widget.item.id!);
    });
  }

  Future<void> _showAddOnQuantityDialog(AddOn addOn) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    double currentPrice = addOn.price;
    int quantity = 1;
    final nameController = TextEditingController(text: addOn.name);
    final priceController = TextEditingController(text: currentPrice.toStringAsFixed(2));
    
    await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Add Add-on',
            style: TextStyle(
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  'Name',
                  style: TextStyle(
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  style: TextStyle(
                    color: isDark ? AppTheme.darkText : AppTheme.lightText,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Add-on name',
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
                    fillColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                  ),
                ),
                const SizedBox(height: 16),
                // Price
                Text(
                  'Price',
                  style: TextStyle(
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    color: isDark ? AppTheme.darkText : AppTheme.lightText,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
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
                    fillColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                    prefixText: 'Rs. ',
                    prefixStyle: TextStyle(
                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                    ),
                  ),
                  onChanged: (value) {
                    final price = double.tryParse(value);
                    if (price != null && price >= 0) {
                      setDialogState(() {
                        currentPrice = price;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),
                // Quantity
                Text(
                  'Quantity',
                  style: TextStyle(
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        if (quantity > 1) {
                          setDialogState(() {
                            quantity--;
                          });
                        }
                      },
                      icon: Icon(
                        Icons.remove_circle_outline,
                        color: quantity > 1
                            ? AppTheme.darkPrimary
                            : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                      ),
                      iconSize: 32,
                    ),
                    Container(
                      width: 60,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppTheme.darkSurface : AppTheme.lightTextSecondary.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        quantity.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? AppTheme.darkText : AppTheme.lightText,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setDialogState(() {
                          quantity++;
                        });
                      },
                      icon: Icon(
                        Icons.add_circle_outline,
                        color: AppTheme.darkPrimary,
                      ),
                      iconSize: 32,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Total price
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total:',
                        style: TextStyle(
                          color: isDark ? AppTheme.darkText : AppTheme.lightText,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _EventItemsScreenState.formatPrice(currentPrice * quantity),
                        style: TextStyle(
                          color: AppTheme.darkPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
                final finalPrice = double.tryParse(priceText);
                
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Please enter a name'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                
                if (finalPrice == null || finalPrice < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Please enter a valid price'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                
                Navigator.pop(context);
                // Add to added add-ons
                setState(() {
                  addedAddOns[addOn.id!] = _AddedAddOn(
                    addOn: addOn,
                    name: name,
                    price: finalPrice,
                    quantity: quantity,
                  );
                });
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
      ),
    );
    
    nameController.dispose();
    priceController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: widget.isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 700, maxWidth: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add-ons for ${widget.item.name}',
                    style: TextStyle(
                      color: widget.isDark ? AppTheme.darkText : AppTheme.lightText,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: widget.isDark ? AppTheme.darkText : AppTheme.lightText,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Two sections
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Available section
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.isDark ? AppTheme.darkSurface : AppTheme.lightTextSecondary.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Available',
                                  style: TextStyle(
                                    color: widget.isDark ? AppTheme.darkText : AppTheme.lightText,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_rounded),
                                  color: AppTheme.darkPrimary,
                                  onPressed: () => _addAddOn(),
                                  tooltip: 'Add Add-on',
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: FutureBuilder<List<AddOn>>(
                              future: _addOnsFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                
                                if (snapshot.hasError) {
                                  return Center(
                                    child: Text(
                                      'Error loading add-ons: ${snapshot.error}',
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  );
                                }
                                
                                final addOns = snapshot.data ?? [];
                                // Show all add-ons in available (don't filter out added ones)
                                final availableAddOns = addOns;
                                
                                if (availableAddOns.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_circle_outline,
                                          size: 60,
                                          color: widget.isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No add-ons available',
                                          style: TextStyle(
                                            color: widget.isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                
                                return ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  itemCount: availableAddOns.length,
                                  itemBuilder: (context, index) {
                                    final addOn = availableAddOns[index];
                                    return _buildAvailableAddOnCard(addOn);
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Added section
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.isDark ? AppTheme.darkSurface : AppTheme.lightTextSecondary.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Added',
                              style: TextStyle(
                                color: widget.isDark ? AppTheme.darkText : AppTheme.lightText,
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          Expanded(
                            child: addedAddOns.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.shopping_cart_outlined,
                                          size: 60,
                                          color: widget.isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No add-ons added',
                                          style: TextStyle(
                                            color: widget.isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    itemCount: addedAddOns.length,
                                    itemBuilder: (context, index) {
                                      final addedAddOn = addedAddOns.values.toList()[index];
                                      return _buildAddedAddOnCard(addedAddOn);
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Confirm button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: widget.isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      // Save selections to database
                      // Delete all existing add-on selections first
                      await widget.dbService.deleteAllItemAddOnSelections(widget.item.id!);
                      
                      // Save all added add-ons
                      for (var addedAddOn in addedAddOns.values) {
                        await widget.dbService.saveItemAddOnSelection(
                          widget.item.id!,
                          addedAddOn.addOn.id!,
                          addedAddOn.quantity,
                        );
                      }
                      Navigator.pop(context, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.darkPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Confirm'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableAddOnCard(AddOn addOn) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: widget.isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      child: ListTile(
        title: Text(
          addOn.name,
          style: TextStyle(
            color: widget.isDark ? AppTheme.darkText : AppTheme.lightText,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Text(
          _EventItemsScreenState.formatPrice(addOn.price),
          style: TextStyle(
            color: AppTheme.darkPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        onTap: () => _showAddOnQuantityDialog(addOn),
      ),
    );
  }

  Widget _buildAddedAddOnCard(_AddedAddOn addedAddOn) {
    final totalPrice = addedAddOn.price * addedAddOn.quantity;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: widget.isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      child: ListTile(
        title: Text(
          addedAddOn.name,
          style: TextStyle(
            color: widget.isDark ? AppTheme.darkText : AppTheme.lightText,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${addedAddOn.quantity}x ',
              style: TextStyle(
                color: widget.isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                fontSize: 14,
              ),
            ),
            Text(
              _EventItemsScreenState.formatPrice(totalPrice),
              style: TextStyle(
                color: AppTheme.darkPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 20,
              ),
              onPressed: () {
                // Remove from added
                setState(() {
                  addedAddOns.remove(addedAddOn.addOn.id);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addAddOn() async {
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
          'Add Add-on',
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
                labelText: 'Add-on Name',
                labelStyle: TextStyle(
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
                hintText: 'Enter add-on name',
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
                fillColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
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
                hintText: '0.00',
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
                fillColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
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
        final addOn = AddOn(
          itemId: widget.item.id!,
          name: result['name'],
          price: result['price'],
        );
        await widget.dbService.insertAddOn(addOn);
        _refreshAddOns();
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
    
    nameController.dispose();
    priceController.dispose();
  }
}

