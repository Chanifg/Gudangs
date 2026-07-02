import 'dart:io';
import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imagePath;
  final String name;
  final double radius;
  final Color? iconColor;
  final Color? backgroundColor;

  const ProfileAvatar({
    super.key,
    required this.imagePath,
    required this.name,
    this.radius = 24,
    this.iconColor,
    this.backgroundColor,
  });

  Color _getPresetBgColor(int index) {
    final colors = [
      const Color(0xFF006E2F), // Green
      const Color(0xFF0B1C30), // Navy
      const Color(0xFF1E3A8A), // Blue
      const Color(0xFF7C3AED), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFFEF4444), // Red
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF10B981), // Emerald
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final nameLetter = name.isNotEmpty ? name[0].toUpperCase() : 'A';

    if (imagePath != null && imagePath!.isNotEmpty) {
      if (imagePath!.startsWith('preset:')) {
        final idx = int.tryParse(imagePath!.split(':').last) ?? 0;
        return CircleAvatar(
          radius: radius,
          backgroundColor: _getPresetBgColor(idx),
          child: Text(
            nameLetter,
            style: TextStyle(
              fontSize: radius * 0.8,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      } else {
        final file = File(imagePath!);
        if (file.existsSync()) {
          return CircleAvatar(
            radius: radius,
            backgroundImage: FileImage(file),
          );
        }
      }
    }

    // Default Fallback
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? colorScheme.primary.withValues(alpha: 0.1),
      child: Icon(
        Icons.person,
        color: iconColor ?? colorScheme.primary,
        size: radius * 1.1,
      ),
    );
  }
}
