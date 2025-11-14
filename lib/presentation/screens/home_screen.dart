import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_manager.dart';
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

