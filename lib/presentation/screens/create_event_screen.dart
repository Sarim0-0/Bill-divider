import 'package:flutter/material.dart';
import '../../models/person.dart';
import '../../models/event.dart';
import '../../services/database_service.dart';
import '../../core/theme/app_theme.dart';
import 'event_items_screen.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _eventNameController = TextEditingController();
  List<Person> _allPeople = [];
  Set<int> _selectedPeopleIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPeople();
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    super.dispose();
  }

  Future<void> _loadPeople() async {
    setState(() => _isLoading = true);
    final people = await _dbService.getAllPeople();
    setState(() {
      _allPeople = people;
      _isLoading = false;
    });
  }

  Future<void> _addPerson() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Add Person',
          style: TextStyle(
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: TextStyle(
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
          ),
          decoration: InputDecoration(
            hintText: 'Enter name',
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
              if (textController.text.trim().isNotEmpty) {
                Navigator.pop(context, textController.text.trim());
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

    if (result != null && result.isNotEmpty) {
      try {
        final personId = await _dbService.insertPerson(Person(name: result));
        _loadPeople();
        // Auto-select the newly added person
        setState(() {
          _selectedPeopleIds.add(personId);
        });
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

  Future<void> _createEvent() async {
    if (_eventNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an event name'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedPeopleIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one person'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final now = DateTime.now();
      final event = Event(
        name: _eventNameController.text.trim(),
        date: now.toIso8601String().split('T')[0], // YYYY-MM-DD format
      );

      final eventId = await _dbService.insertEvent(event);

      // Add selected people to event
      for (final personId in _selectedPeopleIds) {
        await _dbService.addPersonToEvent(eventId, personId);
      }

      if (mounted) {
        // Navigate to event items screen
        Navigator.pop(context); // Close create event screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EventItemsScreen(event: event.copyWith(id: eventId)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating event: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
          'Create Event',
          style: TextStyle(
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Event name input
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _eventNameController,
              autofocus: true,
              style: TextStyle(
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
                fontSize: 18,
              ),
              decoration: InputDecoration(
                labelText: 'Event Name',
                labelStyle: TextStyle(
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
                hintText: 'Enter event name',
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
                fillColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              ),
            ),
          ),
          // People list header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Text(
                  'Select People',
                  style: TextStyle(
                    color: isDark ? AppTheme.darkText : AppTheme.lightText,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_selectedPeopleIds.length} selected',
                  style: TextStyle(
                    color: AppTheme.darkPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // People list
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.darkPrimary,
                    ),
                  )
                : _allPeople.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline_rounded,
                              size: 64,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No people added yet',
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
                        itemCount: _allPeople.length,
                        itemBuilder: (context, index) {
                          final person = _allPeople[index];
                          final isSelected = _selectedPeopleIds.contains(person.id);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(
                                      color: AppTheme.darkPrimary,
                                      width: 2,
                                    )
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: CheckboxListTile(
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedPeopleIds.add(person.id!);
                                  } else {
                                    _selectedPeopleIds.remove(person.id);
                                  }
                                });
                              },
                              title: Text(
                                person.name,
                                style: TextStyle(
                                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                              activeColor: AppTheme.darkPrimary,
                              checkColor: Colors.white,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Add Person button (bottom left)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addPerson,
                  icon: const Icon(Icons.person_add_rounded),
                  label: const Text('Add Person'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.darkPrimary,
                    side: BorderSide(color: AppTheme.darkPrimary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Create Event button (bottom right)
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _createEvent,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Create Event'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.darkSecondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

