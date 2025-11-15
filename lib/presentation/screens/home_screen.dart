import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_manager.dart';
import '../../core/theme/app_theme.dart';
import '../../services/database_service.dart';
import '../widgets/glowing_button.dart';
import 'add_people_screen.dart';
import 'add_event_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeManager = Provider.of<ThemeManager>(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1A1D29) // Solid dark gray background
              : const Color(0xFFF8FAFC), // Light background
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar with theme toggle
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _ThemeToggleButton(
                      isDark: isDark,
                      onToggle: () => themeManager.toggleTheme(),
                    ),
                  ],
                ),
              ),
              // Main content with buttons
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // On mobile, stack buttons vertically; on larger screens, show side by side
                        final isMobile = constraints.maxWidth < 600;
                        if (isMobile) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GlowingButton(
                                label: 'Add People',
                                icon: Icons.person_add_rounded,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AddPeopleScreen(),
                                    ),
                                  );
                                },
                                glowColor: const Color(0xFF6366F1), // Indigo
                              ),
                              const SizedBox(height: 24),
                              GlowingButton(
                                label: 'Add Event',
                                icon: Icons.event_rounded,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AddEventScreen(),
                                    ),
                                  );
                                },
                                glowColor: const Color(0xFF8B5CF6), // Purple
                              ),
                              const SizedBox(height: 24),
                              // Clear All Data button
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: OutlinedButton.icon(
                                  onPressed: () => _showClearDataDialog(context, isDark),
                                  icon: Icon(
                                    Icons.delete_sweep_rounded,
                                    color: Colors.red.withOpacity(0.8),
                                  ),
                                  label: Text(
                                    'Clear All Data',
                                    style: TextStyle(
                                      color: Colors.red.withOpacity(0.8),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    side: BorderSide(
                                      color: Colors.red.withOpacity(0.5),
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              GlowingButton(
                                label: 'Add People',
                                icon: Icons.person_add_rounded,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AddPeopleScreen(),
                                    ),
                                  );
                                },
                                glowColor: const Color(0xFF6366F1), // Indigo
                              ),
                              GlowingButton(
                                label: 'Add Event',
                                icon: Icons.event_rounded,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AddEventScreen(),
                                    ),
                                  );
                                },
                                glowColor: const Color(0xFF8B5CF6), // Purple
                              ),
                            ],
                          );
                        }
                      },
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

  void _showClearDataDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Clear All Data',
          style: TextStyle(
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete ALL data? This will remove all people, events, items, variants, and add-ons. This action cannot be undone.',
          style: TextStyle(
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
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
              Navigator.pop(context); // Close dialog
              try {
                final dbService = DatabaseService();
                await dbService.clearAllData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('All data cleared successfully'),
                      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error clearing data: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Clear All',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeToggleButton extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggle;

  const _ThemeToggleButton({
    required this.isDark,
    required this.onToggle,
  });

  @override
  State<_ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<_ThemeToggleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    if (widget.isDark) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_ThemeToggleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDark != widget.isDark) {
      if (widget.isDark) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return GestureDetector(
          onTap: widget.onToggle,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? const Color(0xFF1A1F3A)
                  : const Color(0xFFE5E7EB),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Sun icon (light mode)
                Opacity(
                  opacity: 1 - _controller.value,
                  child: Icon(
                    Icons.light_mode_rounded,
                    color: const Color(0xFFF59E0B),
                    size: 22,
                  ),
                ),
                // Moon icon (dark mode)
                Opacity(
                  opacity: _controller.value,
                  child: Icon(
                    Icons.dark_mode_rounded,
                    color: const Color(0xFF6366F1),
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

