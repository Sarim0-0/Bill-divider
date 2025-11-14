import 'package:flutter/material.dart';
import '../../models/person.dart';
import '../../models/event.dart';
import '../../services/database_service.dart';
import '../../core/theme/app_theme.dart';
import 'final_details_screen.dart';

class PersonDetailsScreen extends StatefulWidget {
  final Person person;

  const PersonDetailsScreen({
    super.key,
    required this.person,
  });

  @override
  State<PersonDetailsScreen> createState() => _PersonDetailsScreenState();
}

class _PersonDetailsScreenState extends State<PersonDetailsScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Event> _events = [];
  Map<int, bool> _eventPaidStatus = {}; // event_id -> has paid
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    final events = await _dbService.getEventsForPerson(widget.person.id!);
    
    // Load paid status for each event
    Map<int, bool> paidStatus = {};
    for (var event in events) {
      if (event.id != null) {
        final hasPaid = await _dbService.hasPersonPaidForEvent(event.id!, widget.person.id!);
        paidStatus[event.id!] = hasPaid;
      }
    }
    
    setState(() {
      _events = events;
      _eventPaidStatus = paidStatus;
      _isLoading = false;
    });
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
      ),
      body: Column(
        children: [
          // Person header
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.darkPrimary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    size: 48,
                    color: AppTheme.darkPrimary,
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
                  'Events participated in',
                  style: TextStyle(
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          // Events list
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.darkPrimary,
                    ),
                  )
                : _events.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_outlined,
                              size: 64,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No events yet',
                              style: TextStyle(
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _events.length,
                        itemBuilder: (context, index) {
                          final event = _events[index];
                          final hasPaid = _eventPaidStatus[event.id] ?? true;
                          final shouldShowRed = !hasPaid;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: shouldShowRed
                                  ? Colors.red.withOpacity(isDark ? 0.3 : 0.2)
                                  : (isDark ? AppTheme.darkSurface : AppTheme.lightSurface),
                              border: shouldShowRed
                                  ? Border.all(color: Colors.red.withOpacity(0.5), width: 2)
                                  : null,
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
                                horizontal: 16,
                                vertical: 12,
                              ),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.darkSecondary.withOpacity(0.2),
                                ),
                                child: Icon(
                                  Icons.event_rounded,
                                  color: AppTheme.darkSecondary,
                                  size: 26,
                                ),
                              ),
                              title: Text(
                                event.name,
                                style: TextStyle(
                                  color: shouldShowRed
                                      ? Colors.red.shade700
                                      : (isDark ? AppTheme.darkText : AppTheme.lightText),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  _formatDate(event.date),
                                  style: TextStyle(
                                    color: shouldShowRed
                                        ? Colors.red.shade600
                                        : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              onTap: () async {
                                // Load order items and payment settings for final details screen
                                final orderItemsRaw = await _dbService.getOrderItemsByEvent(event.id!);
                                
                                // Load add-ons for each order item
                                List<Map<String, dynamic>> orderItems = [];
                                for (var orderItemRaw in orderItemsRaw) {
                                  final orderItem = Map<String, dynamic>.from(orderItemRaw);
                                  final addOns = await _dbService.getOrderItemAddOns(orderItem['id'] as int);
                                  orderItem['addons'] = addOns;
                                  orderItems.add(orderItem);
                                }
                                
                                // Load payment settings
                                final paymentSettings = await _dbService.getEventPaymentSettings(event.id!);
                                
                                if (context.mounted) {
                                  final result = await Navigator.push(
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
                                      ),
                                    ),
                                  );
                                  
                                  // Reload events to update paid status after returning
                                  if (result == true) {
                                    _loadEvents();
                                  }
                                }
                              },
                            ),
                          );
                        },
                      ),
          ),
          // OK button
          Padding(
            padding: const EdgeInsets.all(24.0),
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





