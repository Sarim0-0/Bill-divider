import 'package:flutter/material.dart';
import '../../models/person.dart';
import '../../services/database_service.dart';
import '../../core/theme/app_theme.dart';
import 'person_details_screen.dart';

class AddPeopleScreen extends StatefulWidget {
  const AddPeopleScreen({super.key});

  @override
  State<AddPeopleScreen> createState() => _AddPeopleScreenState();
}

class _AddPeopleScreenState extends State<AddPeopleScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Person> _people = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPeople();
  }

  Future<void> _loadPeople() async {
    setState(() => _isLoading = true);
    final people = await _dbService.getAllPeople();
    setState(() {
      _people = people;
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
        await _dbService.insertPerson(Person(name: result));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$result added successfully'),
              backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
            ),
          );
        }
        _loadPeople();
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

  Future<void> _deletePerson(Person person) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete Person',
          style: TextStyle(
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${person.name}"?',
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

    if (confirm == true) {
      try {
        await _dbService.deletePerson(person.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${person.name} deleted'),
              backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
            ),
          );
        }
        _loadPeople();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting person: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
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
          'People',
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
          : _people.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline_rounded,
                        size: 80,
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
                  itemCount: _people.length,
                  itemBuilder: (context, index) {
                    final person = _people[index];
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
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.darkPrimary.withOpacity(0.2),
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            color: AppTheme.darkPrimary,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          person.name,
                          style: TextStyle(
                            color: isDark ? AppTheme.darkText : AppTheme.lightText,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red.withOpacity(0.7),
                          ),
                          onPressed: () => _deletePerson(person),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PersonDetailsScreen(person: person),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPerson,
        backgroundColor: AppTheme.darkPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

