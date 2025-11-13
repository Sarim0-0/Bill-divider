import 'package:flutter/material.dart';

class GlowingButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color glowColor;

  const GlowingButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    required this.glowColor,
  });

  @override
  State<GlowingButton> createState() => _GlowingButtonState();
}

class _GlowingButtonState extends State<GlowingButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Button colors based on theme
    final buttonColor = isDark 
        ? const Color(0xFF2A2F4A) // Dark gray for dark theme
        : const Color(0xFFE5E7EB); // Light gray for light theme
    
    // Text/icon color
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: buttonColor,
            boxShadow: [
              // Radiant glow from left and bottom edges (like in the image)
              // Left edge glow - more intense closer to edge
              BoxShadow(
                color: widget.glowColor.withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: -8,
                offset: const Offset(-18, 0),
              ),
              BoxShadow(
                color: widget.glowColor.withOpacity(0.35),
                blurRadius: 45,
                spreadRadius: -12,
                offset: const Offset(-22, 0),
              ),
              BoxShadow(
                color: widget.glowColor.withOpacity(0.25),
                blurRadius: 60,
                spreadRadius: -16,
                offset: const Offset(-26, 0),
              ),
              // Bottom edge glow
              BoxShadow(
                color: widget.glowColor.withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: -8,
                offset: const Offset(0, 18),
              ),
              BoxShadow(
                color: widget.glowColor.withOpacity(0.35),
                blurRadius: 45,
                spreadRadius: -12,
                offset: const Offset(0, 22),
              ),
              BoxShadow(
                color: widget.glowColor.withOpacity(0.25),
                blurRadius: 60,
                spreadRadius: -16,
                offset: const Offset(0, 26),
              ),
              // Corner glow (where left and bottom meet) - strongest here
              BoxShadow(
                color: widget.glowColor.withOpacity(0.4),
                blurRadius: 35,
                spreadRadius: -10,
                offset: const Offset(-12, 12),
              ),
              // Subtle shadow for depth
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.08),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 42,
                color: textColor,
              ),
              const SizedBox(height: 10),
              Text(
                widget.label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

