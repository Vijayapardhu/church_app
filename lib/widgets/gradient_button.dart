import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final double borderRadius;
  final List<Color> colors;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.borderRadius = 30,
    this.colors = const [Color(0xFFFFE5B4), Color(0xFFFDF6F0)],
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(borderRadius),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.brown[700]),
                SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  color: Colors.brown[700],
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 