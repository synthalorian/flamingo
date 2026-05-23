// Data model for a tool in the Flamingo grid.
import 'package:flutter/material.dart';

class ToolItem {
  final String id;
  final String title;
  final String description;
  final String routePath;
  final bool isComingSoon;
  final IconData icon;
  final Color accentColor;

  ToolItem({
    required this.id,
    required this.title,
    required this.description,
    required this.routePath,
    this.isComingSoon = false,
    required this.icon,
    required this.accentColor,
  });
}
