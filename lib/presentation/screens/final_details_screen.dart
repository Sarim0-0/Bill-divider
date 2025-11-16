import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../models/person.dart';
import '../../services/database_service.dart';
import '../../core/theme/app_theme.dart';
import 'home_screen.dart';
import 'add_event_screen.dart';

class FinalDetailsScreen extends StatefulWidget {
  final Event event;
  final List<Map<String, dynamic>> orderItems;
  final String? paymentMethod;
  final String? taxType;
  final double? discountPercentage;
  final bool isFoodpanda;
  final double? miscellaneousAmount;
  final double? calculatedTotal;
  final bool returnToEvents; // If true, Close button returns to events list
  final VoidCallback? onClose; // Custom callback when closing (if provided, overrides default navigation). Called after popping this screen.

  const FinalDetailsScreen({
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
    this.onClose,
  });

  @override
  State<FinalDetailsScreen> createState() => _FinalDetailsScreenState();
}

class _FinalDetailsScreenState extends State<FinalDetailsScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Person> _people = [];
  Map<int, double> _personTotals = {}; // person_id -> total amount
  Map<int, List<Map<String, dynamic>>> _personItems = {}; // person_id -> list of items with amounts
  Set<int> _paidPersonIds = {}; // person_id -> whether they've paid
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Load people in event
    final people = await _dbService.getPeopleInEvent(widget.event.id!);
    
    // Initialize person totals and items
    Map<int, double> personTotals = {};
    Map<int, List<Map<String, dynamic>>> personItems = {};
    
    for (var person in people) {
      personTotals[person.id!] = 0.0;
      personItems[person.id!] = [];
    }
    
    // Load assignments for all order items
    for (var orderItem in widget.orderItems) {
      final orderItemId = orderItem['id'] as int;
      final assignments = await _dbService.getItemPersonAssignments(orderItemId);
      
      for (var assignment in assignments) {
        final personId = assignment['person_id'] as int;
        final amount = (assignment['amount'] as num).toDouble();
        
        // Add to person's total
        personTotals[personId] = (personTotals[personId] ?? 0.0) + amount;
        
        // Add item details to person's items list
        if (!personItems.containsKey(personId)) {
          personItems[personId] = [];
        }
        personItems[personId]!.add({
          'orderItem': orderItem,
          'amount': amount,
        });
      }
    }
    
    // Load paid status for all people in the event
    final paidStatus = await _dbService.getEventPaidStatus(widget.event.id!);
    Set<int> paidPersonIds = {};
    for (var entry in paidStatus.entries) {
      if (entry.value) {
        paidPersonIds.add(entry.key);
      }
    }
    
    // Check if there's a "paid by" person and automatically mark them as paid
    final paymentSettings = await _dbService.getEventPaymentSettings(widget.event.id!);
    if (paymentSettings != null && paymentSettings['paid_by_person_id'] != null) {
      final paidByPersonId = paymentSettings['paid_by_person_id'] as int;
      if (!paidPersonIds.contains(paidByPersonId)) {
        // Automatically mark the person who paid as paid
        await _dbService.savePersonPaidStatus(
          eventId: widget.event.id!,
          personId: paidByPersonId,
          isPaid: true,
        );
        paidPersonIds.add(paidByPersonId);
      }
    }
    
    setState(() {
      _people = people;
      _personTotals = personTotals;
      _personItems = personItems;
      _paidPersonIds = paidPersonIds;
      _isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Final Details',
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
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
          ),
          onPressed: () {
            if (widget.onClose != null) {
              Navigator.pop(context);
              widget.onClose!();
            } else {
              // Default: navigate back to HomeScreen
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            }
          },
        ),
      ),
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: _isLoading
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
                  // People and their totals
                  Text(
                    'People & Amounts',
                    style: TextStyle(
                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._people.map((person) {
                    final personId = person.id!;
                    final total = _personTotals[personId] ?? 0.0;
                    final items = _personItems[personId] ?? [];
                    
                    if (total == 0.0 && items.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    
                    final isPaid = _paidPersonIds.contains(personId);
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isPaid 
                            ? Colors.green.withOpacity(0.2)
                            : (isDark ? AppTheme.darkSurface : AppTheme.lightSurface),
                        border: isPaid
                            ? Border.all(color: Colors.green, width: 2)
                            : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Person name, total, and paid checkbox
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: isPaid,
                                      onChanged: (value) {
                                        setState(() {
                                          if (value == true) {
                                            _paidPersonIds.add(personId);
                                          } else {
                                            _paidPersonIds.remove(personId);
                                          }
                                        });
                                        // Save paid status to database
                                        _dbService.savePersonPaidStatus(
                                          eventId: widget.event.id!,
                                          personId: personId,
                                          isPaid: value ?? false,
                                        );
                                      },
                                      activeColor: Colors.green,
                                    ),
                                    Expanded(
                                      child: Text(
                                        person.name,
                                        style: TextStyle(
                                          color: isPaid
                                              ? Colors.green.shade700
                                              : (isDark ? AppTheme.darkText : AppTheme.lightText),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _formatPrice(total),
                                  style: TextStyle(
                                    color: isPaid
                                        ? Colors.green.shade700
                                        : AppTheme.darkPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.end,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (items.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 12),
                            Text(
                              'Items:',
                              style: TextStyle(
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Item breakdown
                            ...items.map((itemData) {
                              final orderItem = itemData['orderItem'] as Map<String, dynamic>;
                              final amount = itemData['amount'] as double;
                              final itemName = orderItem['item_name'] as String;
                              final variantName = orderItem['variant_name'] as String?;
                              final quantity = orderItem['quantity'] as int;
                              final addOns = orderItem['addons'] as List<Map<String, dynamic>>? ?? [];
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  itemName,
                                                  style: TextStyle(
                                                    color: isDark ? AppTheme.darkText : AppTheme.lightText,
                                                    fontSize: 12,
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
                                                          fontSize: 9,
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Text(
                                                          variantName,
                                                          style: TextStyle(
                                                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                                            fontSize: 9,
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
                                                            fontSize: 9,
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            '${addOn['addon_name']} x${addOn['quantity']}',
                                                            style: TextStyle(
                                                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                                              fontSize: 9,
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
                                                            maxLines: 1,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  )).toList(),
                                                ],
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Qty: $quantity',
                                                  style: TextStyle(
                                                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Flexible(
                                            child: Text(
                                              _formatPrice(amount),
                                              style: TextStyle(
                                                color: AppTheme.darkPrimary,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              textAlign: TextAlign.end,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 24),
                  // Grand Total
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Grand Total:',
                          style: TextStyle(
                            color: isDark ? AppTheme.darkText : AppTheme.lightText,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _formatPrice(_personTotals.values.fold(0.0, (sum, amount) => sum + amount)),
                          style: TextStyle(
                            color: AppTheme.darkPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Close Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (widget.onClose != null) {
                          Navigator.pop(context);
                          widget.onClose!();
                        } else {
                          // Default: navigate back to HomeScreen
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const HomeScreen()),
                            (route) => false,
                          );
                        }
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
                        'Close',
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

