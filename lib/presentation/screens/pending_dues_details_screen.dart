import 'package:flutter/material.dart';
import '../../models/person.dart';
import '../../models/event.dart';
import '../../services/database_service.dart';
import '../../core/theme/app_theme.dart';
import 'final_details_screen.dart';

class PendingDuesDetailsScreen extends StatefulWidget {
  final Person person;

  const PendingDuesDetailsScreen({
    super.key,
    required this.person,
  });

  @override
  State<PendingDuesDetailsScreen> createState() => _PendingDuesDetailsScreenState();
}

class _PendingDuesDetailsScreenState extends State<PendingDuesDetailsScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Map<String, dynamic>> _pendingDues = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingDues();
  }

  Future<void> _loadPendingDues() async {
    setState(() => _isLoading = true);
    if (widget.person.id != null) {
      final dues = await _dbService.getPersonPendingDuesBreakdown(widget.person.id!);
      setState(() {
        _pendingDues = dues;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  String _formatPrice(double price) {
    return 'Rs. ${price.toStringAsFixed(2)}';
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${date.day} ${months[date.month - 1]}, ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _navigateToEventDetails(int eventId) async {
    try {
      // Show loading indicator
      if (!mounted) return;
      
      // Get event details
      final event = await _dbService.getEventById(eventId);
      if (event == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Load order items
      final orderItemsRaw = await _dbService.getOrderItemsByEvent(eventId);
      
      // Load add-ons for each order item
      List<Map<String, dynamic>> orderItems = [];
      for (var orderItemRaw in orderItemsRaw) {
        final orderItem = Map<String, dynamic>.from(orderItemRaw);
        final addOns = await _dbService.getOrderItemAddOns(orderItem['id'] as int);
        orderItem['addons'] = addOns;
        orderItems.add(orderItem);
      }
      
      // Load payment settings
      final paymentSettings = await _dbService.getEventPaymentSettings(eventId);
      
      if (!mounted) return;
      
      // Navigate to FinalDetailsScreen with callback to return here
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FinalDetailsScreen(
            event: event,
            orderItems: orderItems,
            paymentMethod: paymentSettings?['payment_method'] as String?,
            taxType: paymentSettings?['tax_type'] as String?,
            discountPercentage: paymentSettings?['discount_percentage'] as double?,
            isFoodpanda: (paymentSettings?['is_foodpanda'] as int? ?? 0) == 1,
            miscellaneousAmount: paymentSettings?['miscellaneous_amount'] as double?,
            calculatedTotal: paymentSettings?['calculated_total'] as double?,
            onClose: () {
              // Refresh pending dues after returning from event details
              _loadPendingDues();
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading event: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Group dues by creditor
    Map<int, Map<String, dynamic>> creditorMap = {};
    for (var due in _pendingDues) {
      final creditorId = due['creditor_id'] as int;
      final creditorName = due['creditor_name'] as String;
      
      if (!creditorMap.containsKey(creditorId)) {
        creditorMap[creditorId] = {
          'creditor_id': creditorId,
          'creditor_name': creditorName,
          'events': <Map<String, dynamic>>[],
          'total': 0.0,
        };
      }
      
      final amount = (due['amount'] as num).toDouble();
      creditorMap[creditorId]!['events'].add(due);
      creditorMap[creditorId]!['total'] = 
          (creditorMap[creditorId]!['total'] as double) + amount;
    }

    final creditorsList = creditorMap.values.toList();
    final grandTotal = _pendingDues.fold<double>(
      0.0,
      (sum, due) => sum + ((due['amount'] as num).toDouble()),
    );

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
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text(
          'Pending Dues',
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
          : _pendingDues.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 80,
                        color: Colors.green.withOpacity(0.7),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No pending dues',
                        style: TextStyle(
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.person.name} has paid all dues',
                        style: TextStyle(
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Person header
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.account_balance_wallet_rounded,
                              size: 48,
                              color: Colors.red.shade700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.person.name,
                            style: TextStyle(
                              color: isDark ? AppTheme.darkText : AppTheme.lightText,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pending Dues Breakdown',
                            style: TextStyle(
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Dues list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: creditorsList.length,
                        itemBuilder: (context, creditorIndex) {
                          final creditorData = creditorsList[creditorIndex];
                          final creditorName = creditorData['creditor_name'] as String;
                          final creditorTotal = creditorData['total'] as double;
                          final events = creditorData['events'] as List<Map<String, dynamic>>;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Creditor header
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      topRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.person_rounded,
                                                  size: 20,
                                                  color: Colors.red.shade700,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Owes $creditorName',
                                                    style: TextStyle(
                                                      color: Colors.red.shade700,
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 2,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${events.length} ${events.length == 1 ? 'event' : 'events'}',
                                              style: TextStyle(
                                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        _formatPrice(creditorTotal),
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Events list
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: events.map((event) {
                                      final eventName = event['event_name'] as String;
                                      final eventDate = event['event_date'] as String;
                                      final eventId = event['event_id'] as int;
                                      final amount = (event['amount'] as num).toDouble();
                                      
                                      return InkWell(
                                        onTap: () => _navigateToEventDetails(eventId),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isDark 
                                                  ? AppTheme.darkSurface 
                                                  : AppTheme.lightTextSecondary.withOpacity(0.2),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.event_rounded,
                                                          size: 16,
                                                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                                        ),
                                                        const SizedBox(width: 6),
                                                        Expanded(
                                                          child: Text(
                                                            eventName,
                                                            style: TextStyle(
                                                              color: isDark ? AppTheme.darkText : AppTheme.lightText,
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
                                                            maxLines: 2,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Padding(
                                                      padding: const EdgeInsets.only(left: 22),
                                                      child: Text(
                                                        _formatDate(eventDate),
                                                        style: TextStyle(
                                                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Row(
                                                children: [
                                                  Text(
                                                    _formatPrice(amount),
                                                    style: TextStyle(
                                                      color: Colors.red.shade600,
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Icon(
                                                    Icons.arrow_forward_ios_rounded,
                                                    size: 12,
                                                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    // Grand total
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Pending:',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatPrice(grandTotal),
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // OK button
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.darkPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'OK',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

