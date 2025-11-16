import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../models/person.dart';
import '../../services/database_service.dart';
import '../../core/theme/app_theme.dart';
import 'final_details_screen.dart';

class DivisionScreen extends StatefulWidget {
  final Event event;
  final List<Map<String, dynamic>> orderItems;
  final String? paymentMethod;
  final String? taxType;
  final double? discountPercentage;
  final bool isFoodpanda;
  final double? miscellaneousAmount;
  final double? calculatedTotal;
  final bool returnToEvents; // If true, Close button in FinalDetailsScreen returns to events list

  const DivisionScreen({
    super.key,
    required this.event,
    required this.orderItems,
    required this.paymentMethod,
    required this.taxType,
    required this.discountPercentage,
    required this.isFoodpanda,
    required this.miscellaneousAmount,
    required this.calculatedTotal,
    this.returnToEvents = false,
  });

  @override
  State<DivisionScreen> createState() => _DivisionScreenState();
}

class _DivisionScreenState extends State<DivisionScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Map<String, dynamic>> _itemTotals = [];
  double _sumTotal = 0.0;
  List<Person> _people = [];
  Map<int, Set<int>> _itemPersonSelections = {}; // order_item_id -> Set<person_id>
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    _calculateItemTotals();
    await _loadPeople();
    await _loadExistingAssignments();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadPeople() async {
    final people = await _dbService.getPeopleInEvent(widget.event.id!);
    setState(() {
      _people = people;
    });
  }

  Future<void> _loadExistingAssignments() async {
    // Load existing assignments for all order items
    for (var orderItem in widget.orderItems) {
      final orderItemId = orderItem['id'] as int;
      final assignments = await _dbService.getItemPersonAssignments(orderItemId);
      
      if (assignments.isNotEmpty) {
        setState(() {
          _itemPersonSelections[orderItemId] = assignments
              .map((a) => a['person_id'] as int)
              .toSet();
        });
      }
    }
  }

  void _calculateItemTotals() {
    // Get discount percentage (0 if not set)
    double discountPercent = widget.discountPercentage ?? 0.0;
    
    // Get miscellaneous amount (0 if not set)
    double miscAmount = widget.miscellaneousAmount ?? 0.0;
    
    // Calculate miscellaneous amount per item (divided equally)
    int itemCount = widget.orderItems.length;
    double miscPerItem = itemCount > 0 ? miscAmount / itemCount : 0.0;
    
    List<Map<String, dynamic>> itemTotals = [];
    double sumTotal = 0.0;
    
    for (var orderItem in widget.orderItems) {
      // Start with base price
      double itemPrice = (orderItem['total_price'] as num).toDouble();
      
      // Add miscellaneous amount per item (behind the scenes)
      itemPrice += miscPerItem;
      
      double finalPrice = itemPrice;
      
      // Apply calculations based on payment method and tax type
      if (widget.paymentMethod == 'Normal' || widget.taxType == 'None') {
        // Just apply discount if set
        if (discountPercent > 0) {
          finalPrice = itemPrice * (1 - discountPercent / 100);
        } else {
          finalPrice = itemPrice;
        }
      } else if (widget.paymentMethod == null || widget.taxType == null) {
        // Just apply discount if set
        if (discountPercent > 0) {
          finalPrice = itemPrice * (1 - discountPercent / 100);
        } else {
          finalPrice = itemPrice;
        }
      } else if (widget.paymentMethod == 'Cash' && widget.taxType == 'Tax Exclusive') {
        // Cash + Tax Exclusive: Calculate 16% tax, then apply discount
        double itemTax = itemPrice * (16.0 / 100);
        double itemAfterTax = itemPrice + itemTax;
        
        if (widget.isFoodpanda) {
          // Foodpanda: discount on base price, tax on original price
          double itemAfterDiscount = itemPrice * (1 - discountPercent / 100);
          finalPrice = itemAfterDiscount + itemTax;
        } else {
          // Normal: discount on after-tax price
          finalPrice = itemAfterTax * (1 - discountPercent / 100);
        }
      } else if (widget.paymentMethod == 'Cash' && widget.taxType == 'Tax Inclusive') {
        // Cash + Tax Inclusive: Show "Included" and just give item total
        // Apply discount if set
        if (discountPercent > 0) {
          finalPrice = itemPrice * (1 - discountPercent / 100);
        } else {
          finalPrice = itemPrice;
        }
      } else if (widget.paymentMethod == 'Card' && widget.taxType == 'Tax Exclusive') {
        // Card + Tax Exclusive: Calculate 5% tax, then apply discount
        double itemTax = itemPrice * (5.0 / 100);
        double itemAfterTax = itemPrice + itemTax;
        
        if (widget.isFoodpanda) {
          // Foodpanda: discount on base price, tax on original price
          double itemAfterDiscount = itemPrice * (1 - discountPercent / 100);
          finalPrice = itemAfterDiscount + itemTax;
        } else {
          // Normal: discount on after-tax price
          finalPrice = itemAfterTax * (1 - discountPercent / 100);
        }
      } else if (widget.paymentMethod == 'Card' && widget.taxType == 'Tax Inclusive') {
        // Card + Tax Inclusive: Calculate 5% tax and subtract it, then apply discount
        double itemTax = itemPrice * (5.0 / 100);
        double itemAfterTax = itemPrice - itemTax; // Tax inclusive: subtract tax
        
        if (widget.isFoodpanda) {
          // Foodpanda: discount on base price, tax on original price
          double itemAfterDiscount = itemPrice * (1 - discountPercent / 100);
          finalPrice = itemAfterDiscount + itemTax;
        } else {
          // Normal: discount on after-tax price
          finalPrice = itemAfterTax * (1 - discountPercent / 100);
        }
      }
      
      itemTotals.add({
        'orderItem': orderItem,
        'finalPrice': finalPrice,
      });
      
      sumTotal += finalPrice;
    }
    
    setState(() {
      _itemTotals = itemTotals;
      _sumTotal = sumTotal;
    });
  }

  String _formatPrice(double price) {
    return 'Rs. ${price.toStringAsFixed(2)}';
  }

  String _getPaymentMethodDisplay() {
    if (widget.paymentMethod == null) return 'Not selected';
    if (widget.paymentMethod == 'Normal') return 'Normal';
    if (widget.paymentMethod == 'Cash') return 'Cash (16%)';
    if (widget.paymentMethod == 'Card') return 'Card (5%)';
    return widget.paymentMethod!;
  }

  String _getTaxTypeDisplay() {
    if (widget.taxType == null) return 'Not selected';
    if (widget.taxType == 'None') return 'None';
    return widget.taxType!;
  }

  Future<void> _showPersonSelectionDialog(
    int orderItemId,
    double finalPrice,
    Set<int> currentSelection,
    bool isDark,
  ) async {
    Set<int> selectedIds = Set<int>.from(currentSelection);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Select People',
            style: TextStyle(
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: _people.isEmpty
                  ? Text(
                      'No people in this event',
                      style: TextStyle(
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _people.length,
                      itemBuilder: (context, index) {
                        final person = _people[index];
                        final isSelected = selectedIds.contains(person.id);
                        return CheckboxListTile(
                          title: Text(
                            person.name,
                            style: TextStyle(
                              color: isDark ? AppTheme.darkText : AppTheme.lightText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          value: isSelected,
                          onChanged: (value) {
                            setDialogState(() {
                              if (value == true) {
                                selectedIds.add(person.id!);
                              } else {
                                selectedIds.remove(person.id);
                              }
                            });
                          },
                          activeColor: AppTheme.darkPrimary,
                        );
                      },
                    ),
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
                'Done',
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

    if (result == true) {
      setState(() {
        if (selectedIds.isEmpty) {
          _itemPersonSelections.remove(orderItemId);
        } else {
          _itemPersonSelections[orderItemId] = selectedIds;
        }
      });
      _saveAssignments(orderItemId, finalPrice);
    }
  }

  Future<void> _saveAssignments(int orderItemId, double finalPrice) async {
    final selectedPersonIds = _itemPersonSelections[orderItemId];
    if (selectedPersonIds == null || selectedPersonIds.isEmpty) {
      // Delete existing assignments if no one is selected
      await _dbService.saveItemPersonAssignments(
        orderItemId: orderItemId,
        assignments: [],
      );
      return;
    }

    // Calculate amount per person
    int personCount = selectedPersonIds.length;
    double amountPerPerson = personCount > 0 ? finalPrice / personCount : finalPrice;

    // Create assignments list
    List<Map<String, dynamic>> assignments = selectedPersonIds.map((personId) {
      return {
        'person_id': personId,
        'amount': amountPerPerson,
      };
    }).toList();

    // Save to database
    await _dbService.saveItemPersonAssignments(
      orderItemId: orderItemId,
      assignments: assignments,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Division',
          style: TextStyle(
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? AppTheme.darkText : AppTheme.lightText,
        ),
      ),
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: _isLoading || _itemTotals.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment Settings Details
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Settings',
                          style: TextStyle(
                            color: isDark ? AppTheme.darkText : AppTheme.lightText,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow('Payment Method:', _getPaymentMethodDisplay(), isDark),
                        const SizedBox(height: 8),
                        _buildDetailRow('Tax Type:', _getTaxTypeDisplay(), isDark),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          'Discount:',
                          widget.discountPercentage != null
                              ? '${widget.discountPercentage!.toStringAsFixed(0)}%'
                              : 'None',
                          isDark,
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          'Foodpanda:',
                          widget.isFoodpanda ? 'Yes' : 'No',
                          isDark,
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          'Miscellaneous:',
                          widget.miscellaneousAmount != null
                              ? _formatPrice(widget.miscellaneousAmount!)
                              : 'None',
                          isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Items List
                  Text(
                    'Items',
                    style: TextStyle(
                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._itemTotals.asMap().entries.map((entry) {
                    final index = entry.key;
                    final itemData = entry.value;
                    final orderItem = itemData['orderItem'] as Map<String, dynamic>;
                    final finalPrice = itemData['finalPrice'] as double;
                    final itemName = orderItem['item_name'] as String;
                    final variantName = orderItem['variant_name'] as String?;
                    final quantity = orderItem['quantity'] as int;
                    final orderItemId = orderItem['id'] as int;
                    final addOns = orderItem['addons'] as List<Map<String, dynamic>>? ?? [];
                    final selectedPersonIds = _itemPersonSelections[orderItemId] ?? <int>{};
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      itemName,
                                      style: TextStyle(
                                        color: isDark ? AppTheme.darkText : AppTheme.lightText,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                    if (variantName != null) ...[
                                      const SizedBox(height: 3),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Variant: ',
                                            style: TextStyle(
                                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                              fontSize: 10,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              variantName,
                                              style: TextStyle(
                                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                                fontSize: 10,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (addOns.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      ...addOns.map((addOn) => Padding(
                                        padding: const EdgeInsets.only(left: 12, top: 1),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '• ',
                                              style: TextStyle(
                                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                                fontSize: 10,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                '${addOn['addon_name']} x${addOn['quantity']}',
                                                style: TextStyle(
                                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                                  fontSize: 10,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )).toList(),
                                    ],
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        'Qty: $quantity',
                                        style: TextStyle(
                                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  _formatPrice(finalPrice),
                                  style: TextStyle(
                                    color: AppTheme.darkPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.end,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Person Selection Button
                          InkWell(
                            onTap: () => _showPersonSelectionDialog(orderItemId, finalPrice, selectedPersonIds, isDark),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isDark ? AppTheme.darkSurface : AppTheme.lightTextSecondary.withOpacity(0.3),
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      selectedPersonIds.isEmpty
                                          ? 'Select People'
                                          : selectedPersonIds.length == 1
                                              ? '1 person selected'
                                              : '${selectedPersonIds.length} people selected',
                                      style: TextStyle(
                                        color: selectedPersonIds.isEmpty
                                            ? (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)
                                            : (isDark ? AppTheme.darkText : AppTheme.lightText),
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Show selected people names
                          if (selectedPersonIds.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: selectedPersonIds.map((personId) {
                                final person = _people.firstWhere(
                                  (p) => p.id == personId,
                                  orElse: () => Person(id: personId, name: 'Unknown'),
                                );
                                final personCount = selectedPersonIds.length;
                                final amountPerPerson = personCount > 0 ? finalPrice / personCount : finalPrice;
                                
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.darkPrimary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppTheme.darkPrimary.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          person.name,
                                          style: TextStyle(
                                            color: AppTheme.darkPrimary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '(${_formatPrice(amountPerPerson)})',
                                        style: TextStyle(
                                          color: AppTheme.darkPrimary.withOpacity(0.7),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 24),
                  // Total
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Total:',
                          style: TextStyle(
                            color: isDark ? AppTheme.darkText : AppTheme.lightText,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            _formatPrice(_sumTotal),
                            style: TextStyle(
                              color: AppTheme.darkPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.calculatedTotal != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Previous Screen Total: ${_formatPrice(widget.calculatedTotal!)}',
                      style: TextStyle(
                        color: _sumTotal == widget.calculatedTotal!
                            ? Colors.green
                            : Colors.orange,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Next Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FinalDetailsScreen(
                              event: widget.event,
                              orderItems: widget.orderItems,
                              paymentMethod: widget.paymentMethod,
                              taxType: widget.taxType,
                              discountPercentage: widget.discountPercentage,
                              isFoodpanda: widget.isFoodpanda,
                              miscellaneousAmount: widget.miscellaneousAmount,
                              calculatedTotal: widget.calculatedTotal,
                              returnToEvents: widget.returnToEvents,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.darkPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Next',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

