import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../services/database_service.dart';
import '../../core/theme/app_theme.dart';
import 'create_event_screen.dart';
import 'event_items_screen.dart';
import 'final_details_screen.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Event> _events = [];
  Map<int, bool> _eventPaidStatus = {}; // event_id -> are all people paid
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    final events = await _dbService.getAllEvents();
    
    // Check paid status for each event
    Map<int, bool> paidStatus = {};
    for (var event in events) {
      final allPaid = await _dbService.areAllPeoplePaid(event.id!);
      paidStatus[event.id!] = allPaid;
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
        title: Text(
          'Events',
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
          : _events.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_outlined,
                        size: 80,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No events added yet',
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
                    final allPaid = _eventPaidStatus[event.id] ?? true;
                    final shouldShowRed = !allPaid;
                    
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
                            color: isDark ? AppTheme.darkText : AppTheme.lightText,
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
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.edit_outlined,
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EventItemsScreen(
                                      event: event,
                                      returnToEvents: true,
                                    ),
                                  ),
                                ).then((_) {
                                  // Reload events to update paid status after returning
                                  _loadEvents();
                                });
                              },
                              tooltip: 'Edit Event',
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.red.withOpacity(0.7),
                              ),
                              onPressed: () async {
                                // Show confirmation dialog
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    title: Text(
                                      'Delete Event',
                                      style: TextStyle(
                                        color: isDark ? AppTheme.darkText : AppTheme.lightText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    content: Text(
                                      'Are you sure you want to delete "${event.name}"? This action cannot be undone.',
                                      style: TextStyle(
                                        color: isDark ? AppTheme.darkText : AppTheme.lightText,
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
                                        child: const Text(
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
                                
                                if (confirm == true) {
                                  try {
                                    await _dbService.deleteEvent(event.id!);
                                    if (context.mounted) {
                                      _loadEvents();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Event "${event.name}" deleted'),
                                          backgroundColor: Colors.green,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error deleting event: ${e.toString()}'),
                                          backgroundColor: Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                              tooltip: 'Delete Event',
                            ),
                          ],
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
                            Navigator.push(
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
                                  returnToEvents: true,
                                ),
                              ),
                            ).then((_) {
                              // Reload events to update paid status after returning from final details
                              _loadEvents();
                            });
                          }
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateEventScreen(),
            ),
          );
          // Reload events if an event was created
          if (result == true) {
            _loadEvents();
          }
        },
        backgroundColor: AppTheme.darkSecondary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

