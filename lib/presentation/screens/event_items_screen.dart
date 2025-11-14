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
  List<Map<String, dynamic>> _orderItems = [];
  bool _isLoading = true;
  
  // Payment and tax settings (nullable to allow no selection)
  String? _paymentMethod; // 'Cash' or 'Card' or null
  String? _taxType; // 'Tax Exclusive' or 'Tax Inclusive' or null
  double? _discountPercentage; // Discount percentage
  bool _isFoodpanda = false; // Foodpanda radio button state
  
  // Calculated values
  double? _calculatedTax;
  double? _calculatedTotal;
  
  // Text controller for discount input
  final TextEditingController _discountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadItems();
    _loadPaymentSettings();
  }
  
  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }
  
  Future<void> _loadPaymentSettings() async {
    final settings = await _dbService.getEventPaymentSettings(widget.event.id!);
    if (settings != null) {
      setState(() {
        _paymentMethod = settings['payment_method'] as String?;
        _taxType = settings['tax_type'] as String?;
        _calculatedTax = settings['calculated_tax'] as double?;
        _calculatedTotal = settings['calculated_total'] as double?;
        _discountPercentage = settings['discount_percentage'] as double?;
        _isFoodpanda = (settings['is_foodpanda'] as int? ?? 0) == 1;
        
        // Set discount controller text if discount exists
        if (_discountPercentage != null) {
          _discountController.text = _discountPercentage!.toStringAsFixed(0);
        }
      });
    }
  }
  
  Future<void> _savePaymentSettings({bool saveCalculated = false}) async {
    // Always save current selections
    // Only update calculated values if saveCalculated is true
    await _dbService.saveEventPaymentSettings(
      eventId: widget.event.id!,
      paymentMethod: _paymentMethod, // Current selection (can be null)
      taxType: _taxType, // Current selection (can be null)
      calculatedTax: saveCalculated ? _calculatedTax : null, // null means preserve existing
      calculatedTotal: saveCalculated ? _calculatedTotal : null, // null means preserve existing
      discountPercentage: _discountPercentage,
      isFoodpanda: _isFoodpanda,
    );
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    final items = await _dbService.getItemsByEvent(widget.event.id!);
    final orderItemsRaw = await _dbService.getOrderItemsByEvent(widget.event.id!);
    
    // Load add-ons for each order item and create mutable copies
    List<Map<String, dynamic>> orderItems = [];
    for (var orderItemRaw in orderItemsRaw) {
      // Create a mutable copy of the map
      final orderItem = Map<String, dynamic>.from(orderItemRaw);
      final addOns = await _dbService.getOrderItemAddOns(orderItem['id'] as int);
      orderItem['addons'] = addOns;
      orderItems.add(orderItem);
    }
    
    setState(() {
      _items = items;
      _orderItems = orderItems;
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
                  'Cancel',
                  style: TextStyle(
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Calculate total price
                  final totalPrice = finalPrice * quantity;
                  
                  // Prepare add-ons list
                  List<Map<String, int>>? addOnsList;
                  if (addOnSelections.isNotEmpty) {
                    addOnsList = addOnSelections.map((addOn) => {
                      'addon_id': addOn['addon_id'] as int,
                      'quantity': addOn['quantity'] as int,
                    }).toList();
                  }
                  
                  // Save order item
                  try {
                    await _dbService.insertOrderItem(
                      eventId: widget.event.id!,
                      itemId: item.id!,
                      variantId: variantSelection?['variant_id'] as int?,
                      quantity: quantity,
                      totalPrice: totalPrice,
                      addOns: addOnsList,
                    );
                    
                    // Reset variant and add-on selections for this item (they're now saved in order)
                    // This ensures the item is ready for a fresh selection next time
                    await _dbService.deleteItemVariantSelection(item.id!);
                    await _dbService.deleteAllItemAddOnSelections(item.id!);
                    
                    Navigator.pop(context);
                    _loadItems(); // Reload to show in Added section
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${item.name} added to order'),
                          backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  } catch (e) {
                    // Even if there's an error, try to reset selections to keep state clean
                    try {
                      await _dbService.deleteItemVariantSelection(item.id!);
                      await _dbService.deleteAllItemAddOnSelections(item.id!);
                    } catch (_) {
                      // Ignore reset errors if save failed
                    }
                    
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
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.darkPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Add to Order'),
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
                    // Available and Added sections (vertically stacked)
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Available Section
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                'Available',
                                style: TextStyle(
                                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
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
                                    // Base price on the right (always shows base price)
                                    trailing: Text(
                                      _formatPrice(item.price),
                                      style: TextStyle(
                                        color: AppTheme.darkPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onTap: () {
                                      _showItemDetails(item);
                                    },
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            // Added Section
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                'Added',
                                style: TextStyle(
                                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _orderItems.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Center(
                                      child: Text(
                                        'No items added to order yet',
                                        style: TextStyle(
                                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    itemCount: _orderItems.length,
                                    itemBuilder: (context, index) {
                                      final orderItem = _orderItems[index];
                                      return _buildOrderItemCard(orderItem, isDark);
                                    },
                                  ),
                            const SizedBox(height: 24),
                            // Payment Method and Tax Type Section
                            Container(
                              margin: const EdgeInsets.all(16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? AppTheme.darkSurface : AppTheme.lightTextSecondary.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Payment Method
                                  Text(
                                    'Payment Method',
                                    style: TextStyle(
                                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Radio<String?>(
                                        value: 'Cash',
                                        groupValue: _paymentMethod,
                                        onChanged: (value) {
                                          setState(() {
                                            // Toggle: if already selected, deselect it
                                            _paymentMethod = (_paymentMethod == 'Cash') ? null : value;
                                            // Don't clear calculated values when changing selection
                                            // They will be recalculated when Calculate is clicked
                                          });
                                          _savePaymentSettings();
                                        },
                                        activeColor: AppTheme.darkPrimary,
                                      ),
                                      Text(
                                        'Cash (16%)',
                                        style: TextStyle(
                                          color: isDark ? AppTheme.darkText : AppTheme.lightText,
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      Radio<String?>(
                                        value: 'Card',
                                        groupValue: _paymentMethod,
                                        onChanged: (value) {
                                          setState(() {
                                            // Toggle: if already selected, deselect it
                                            _paymentMethod = (_paymentMethod == 'Card') ? null : value;
                                            // Don't clear calculated values when changing selection
                                            // They will be recalculated when Calculate is clicked
                                          });
                                          _savePaymentSettings();
                                        },
                                        activeColor: AppTheme.darkPrimary,
                                      ),
                                      Text(
                                        'Card (5%)',
                                        style: TextStyle(
                                          color: isDark ? AppTheme.darkText : AppTheme.lightText,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  // Tax Type
                                  Text(
                                    'Tax Type',
                                    style: TextStyle(
                                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Radio<String?>(
                                        value: 'Tax Exclusive',
                                        groupValue: _taxType,
                                        onChanged: (value) {
                                          setState(() {
                                            // Toggle: if already selected, deselect it
                                            _taxType = (_taxType == 'Tax Exclusive') ? null : value;
                                            // Don't clear calculated values when changing selection
                                            // They will be recalculated when Calculate is clicked
                                          });
                                          _savePaymentSettings();
                                        },
                                        activeColor: AppTheme.darkPrimary,
                                      ),
                                      Text(
                                        'Tax Exclusive',
                                        style: TextStyle(
                                          color: isDark ? AppTheme.darkText : AppTheme.lightText,
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      Radio<String?>(
                                        value: 'Tax Inclusive',
                                        groupValue: _taxType,
                                        onChanged: (value) {
                                          setState(() {
                                            // Toggle: if already selected, deselect it
                                            _taxType = (_taxType == 'Tax Inclusive') ? null : value;
                                            // Don't clear calculated values when changing selection
                                            // They will be recalculated when Calculate is clicked
                                          });
                                          _savePaymentSettings();
                                        },
                                        activeColor: AppTheme.darkPrimary,
                                      ),
                                      Text(
                                        'Tax Inclusive',
                                        style: TextStyle(
                                          color: isDark ? AppTheme.darkText : AppTheme.lightText,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  // Discount Section
                                  Text(
                                    'Discount',
                                    style: TextStyle(
                                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _discountController,
                                          keyboardType: TextInputType.number,
                                          style: TextStyle(
                                            color: isDark ? AppTheme.darkText : AppTheme.lightText,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: '0',
                                            suffixText: '%',
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
                                          onChanged: (value) {
                                            final discount = double.tryParse(value);
                                            setState(() {
                                              _discountPercentage = discount;
                                              _calculatedTax = null;
                                              _calculatedTotal = null;
                                            });
                                            _savePaymentSettings();
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Radio<bool>(
                                        value: true,
                                        groupValue: _isFoodpanda ? true : null,
                                        onChanged: (value) {
                                          setState(() {
                                            // Toggle: if already selected, deselect it
                                            _isFoodpanda = !_isFoodpanda;
                                            _calculatedTax = null;
                                            _calculatedTotal = null;
                                          });
                                          _savePaymentSettings();
                                        },
                                        activeColor: AppTheme.darkPrimary,
                                      ),
                                      Text(
                                        'foodpanda',
                                        style: TextStyle(
                                          color: isDark ? AppTheme.darkText : AppTheme.lightText,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  // Calculate Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _orderItems.isEmpty ? null : _calculateTotal,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.darkPrimary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        disabledBackgroundColor: isDark 
                                            ? AppTheme.darkTextSecondary.withOpacity(0.3)
                                            : AppTheme.lightTextSecondary.withOpacity(0.3),
                                      ),
                                      child: const Text(
                                        'Calculate',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Tax and Total Display
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Tax:',
                                              style: TextStyle(
                                                color: isDark ? AppTheme.darkText : AppTheme.lightText,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              _calculatedTax != null
                                                  ? (_calculatedTax == -1
                                                      ? (_paymentMethod == 'Cash' && _taxType == 'Tax Inclusive'
                                                          ? 'Included'
                                                          : '-')
                                                      : (_taxType == 'Tax Exclusive'
                                                          ? '+${_formatPrice(_calculatedTax!)}'
                                                          : '-${_formatPrice(_calculatedTax!)}'))
                                                  : '',
                                              style: TextStyle(
                                                color: AppTheme.darkPrimary,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Total:',
                                              style: TextStyle(
                                                color: isDark ? AppTheme.darkText : AppTheme.lightText,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              _calculatedTotal != null
                                                  ? _formatPrice(_calculatedTotal!)
                                                  : '',
                                              style: TextStyle(
                                                color: AppTheme.darkPrimary,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
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
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
  
  void _calculateTotal() {
    if (_orderItems.isEmpty) return;
    
    double tax;
    double total;
    
    // Get discount percentage (0 if not set)
    double discountPercent = _discountPercentage ?? 0.0;
    
    // If no payment method or tax type selected, just show total
    if (_paymentMethod == null || _taxType == null) {
      double subtotal = 0.0;
      for (var orderItem in _orderItems) {
        double itemPrice = (orderItem['total_price'] as num).toDouble();
        // Apply discount if set
        if (discountPercent > 0) {
          itemPrice = itemPrice * (1 - discountPercent / 100);
        }
        subtotal += itemPrice;
      }
      tax = -1; // Special value to show "-"
      total = subtotal;
    } else if (_paymentMethod == 'Cash' && _taxType == 'Tax Exclusive') {
      // Cash + Tax Exclusive: Calculate 16% tax on each item, then apply discount
      double subtotal = 0.0;
      double totalTax = 0.0;
      double totalAfterDiscount = 0.0;
      
      for (var orderItem in _orderItems) {
        double itemPrice = (orderItem['total_price'] as num).toDouble();
        double itemTax = itemPrice * (16.0 / 100);
        double itemAfterTax = itemPrice + itemTax;
        
        // Apply discount on after-tax price (unless foodpanda)
        if (_isFoodpanda) {
          // Foodpanda: discount on base price, tax on original price
          double itemAfterDiscount = itemPrice * (1 - discountPercent / 100);
          itemAfterTax = itemAfterDiscount + itemTax; // Tax on original, discount on base
        } else {
          // Normal: discount on after-tax price
          itemAfterTax = itemAfterTax * (1 - discountPercent / 100);
        }
        
        subtotal += itemPrice;
        totalTax += itemTax;
        totalAfterDiscount += itemAfterTax;
      }
      
      tax = totalTax;
      total = totalAfterDiscount;
      
    } else if (_paymentMethod == 'Cash' && _taxType == 'Tax Inclusive') {
      // Cash + Tax Inclusive: Show "Included" and just give item total
      double subtotal = 0.0;
      for (var orderItem in _orderItems) {
        double itemPrice = (orderItem['total_price'] as num).toDouble();
        // Apply discount if set
        if (discountPercent > 0) {
          itemPrice = itemPrice * (1 - discountPercent / 100);
        }
        subtotal += itemPrice;
      }
      
      tax = -1; // Special value to show "Included"
      total = subtotal;
      
    } else if (_paymentMethod == 'Card' && _taxType == 'Tax Exclusive') {
      // Card + Tax Exclusive: Calculate 5% tax on each item, then apply discount
      double subtotal = 0.0;
      double totalTax = 0.0;
      double totalAfterDiscount = 0.0;
      
      for (var orderItem in _orderItems) {
        double itemPrice = (orderItem['total_price'] as num).toDouble();
        double itemTax = itemPrice * (5.0 / 100);
        double itemAfterTax = itemPrice + itemTax;
        
        // Apply discount on after-tax price (unless foodpanda)
        if (_isFoodpanda) {
          // Foodpanda: discount on base price, tax on original price
          double itemAfterDiscount = itemPrice * (1 - discountPercent / 100);
          itemAfterTax = itemAfterDiscount + itemTax; // Tax on original, discount on base
        } else {
          // Normal: discount on after-tax price
          itemAfterTax = itemAfterTax * (1 - discountPercent / 100);
        }
        
        subtotal += itemPrice;
        totalTax += itemTax;
        totalAfterDiscount += itemAfterTax;
      }
      
      tax = totalTax;
      total = totalAfterDiscount;
      
    } else if (_paymentMethod == 'Card' && _taxType == 'Tax Inclusive') {
      // Card + Tax Inclusive: Calculate 5% tax on each item and subtract it, then apply discount
      double subtotal = 0.0;
      double totalTax = 0.0;
      double totalAfterDiscount = 0.0;
      
      for (var orderItem in _orderItems) {
        double itemPrice = (orderItem['total_price'] as num).toDouble();
        double itemTax = itemPrice * (5.0 / 100);
        double itemAfterTax = itemPrice - itemTax; // Tax inclusive: subtract tax
        
        // Apply discount on after-tax price (unless foodpanda)
        if (_isFoodpanda) {
          // Foodpanda: discount on base price, tax on original price
          double itemAfterDiscount = itemPrice * (1 - discountPercent / 100);
          itemAfterTax = itemAfterDiscount + itemTax; // Tax on original, discount on base
        } else {
          // Normal: discount on after-tax price
          itemAfterTax = itemAfterTax * (1 - discountPercent / 100);
        }
        
        subtotal += itemPrice;
        totalTax += itemTax;
        totalAfterDiscount += itemAfterTax;
      }
      
      tax = totalTax;
      total = totalAfterDiscount;
    } else {
      // Fallback (shouldn't happen)
      tax = 0;
      total = 0;
    }
    
    setState(() {
      _calculatedTax = tax;
      _calculatedTotal = total;
    });
    
    // Save calculated values to database
    _savePaymentSettings(saveCalculated: true);
  }

  Widget _buildOrderItemCard(Map<String, dynamic> orderItem, bool isDark) {
    final itemName = orderItem['item_name'] as String;
    final variantName = orderItem['variant_name'] as String?;
    final quantity = orderItem['quantity'] as int;
    final totalPrice = (orderItem['total_price'] as num).toDouble();
    final addOns = orderItem['addons'] as List<Map<String, dynamic>>? ?? [];
    
    // Build subtitle text with variant and add-ons info
    String subtitle = '';
    if (variantName != null) {
      subtitle = 'Variant: $variantName';
    }
    if (addOns.isNotEmpty) {
      if (subtitle.isNotEmpty) subtitle += ' • ';
      subtitle += 'Add-ons: ${addOns.map((a) => '${a['addon_name']} x${a['quantity']}').join(', ')}';
    }
    if (subtitle.isEmpty) {
      subtitle = 'Base item';
    }
    
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
        title: Text(
          itemName,
          style: TextStyle(
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            fontSize: 12,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${quantity}x',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                fontSize: 14,
              ),
            ),
            Text(
              _formatPrice(totalPrice),
              style: TextStyle(
                color: AppTheme.darkPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        onLongPress: () async {
          // Allow deletion on long press
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              title: Text(
                'Delete Item',
                style: TextStyle(
                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                ),
              ),
              content: Text(
                'Are you sure you want to remove this item from the order?',
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    'Delete',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
          
          if (confirmed == true) {
            try {
              await _dbService.deleteOrderItem(orderItem['id'] as int);
              _loadItems();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Item removed from order'),
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
        },
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
  // Track selected variant ID (only one can be selected)
  int? selectedVariantId;
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
        selectedVariantId = variantSelection['variant_id'];
      });
    }
  }

  void _refreshVariants() {
    setState(() {
      _variantsFuture = widget.dbService.getVariantsByItem(widget.item.id!);
    });
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
            // Variants list
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
                            'Select Variant',
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
                          
                          if (variants.isEmpty) {
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
                            itemCount: variants.length,
                            itemBuilder: (context, index) {
                              final variant = variants[index];
                              return _buildVariantCard(variant);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
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
                      if (selectedVariantId == null) {
                        // Remove variant selection if no variant is selected
                        await widget.dbService.deleteItemVariantSelection(widget.item.id!);
                      } else {
                        // Save the selected variant (quantity is always 1)
                        await widget.dbService.saveItemVariantSelection(
                          widget.item.id!,
                          selectedVariantId!,
                          1,
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

  Widget _buildVariantCard(Variant variant) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: widget.isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      child: ListTile(
        leading: Radio<int>(
          value: variant.id!,
          groupValue: selectedVariantId,
          onChanged: (value) {
            setState(() {
              selectedVariantId = value;
            });
          },
          activeColor: AppTheme.darkPrimary,
        ),
        title: Text(
          variant.name,
          style: TextStyle(
            color: widget.isDark ? AppTheme.darkText : AppTheme.lightText,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _EventItemsScreenState.formatPrice(variant.price),
              style: TextStyle(
                color: AppTheme.darkPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.edit_outlined,
                color: widget.isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                size: 20,
              ),
              onPressed: () => _editVariantPrice(variant),
              tooltip: 'Edit Price',
            ),
          ],
        ),
        onTap: () {
          setState(() {
            selectedVariantId = variant.id;
          });
        },
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
    _loadExistingSelections();
  }

  void _loadExistingSelections() async {
    // Load existing add-on selections for this item
    final addOnSelections = await widget.dbService.getItemAddOnsWithDetails(widget.item.id!);
    if (addOnSelections.isNotEmpty) {
      setState(() {
        for (var selection in addOnSelections) {
          addedAddOns[selection['addon_id']] = _AddedAddOn(
            addOn: AddOn(
              id: selection['addon_id'],
              itemId: widget.item.id!,
              name: selection['addon_name'],
              price: (selection['addon_price'] as num).toDouble(),
            ),
            name: selection['addon_name'],
            price: (selection['addon_price'] as num).toDouble(),
            quantity: selection['quantity'],
          );
        }
      });
    }
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

