import 'package:flutter/material.dart';

class TaskConstants {
  static const List<int> colorPalette = [
    0xFFEF5350, // Red
    0xFFEC407A, // Pink
    0xFFAB47BC, // Purple
    0xFF7E57C2, // Deep Purple
    0xFF5C6BC0, // Indigo
    0xFF42A5F5, // Blue
    0xFF29B6F6, // Light Blue
    0xFF26C6DA, // Cyan
    0xFF26A69A, // Teal
    0xFF66BB6A, // Green
    0xFF9CCC65, // Light Green
    0xFFD4E157, // Lime
    0xFFFFEE58, // Yellow
    0xFFFFCA28, // Amber
    0xFFFFA726, // Orange
    0xFFFF7043, // Deep Orange
    0xFF8D6E63, // Brown
    0xFF78909C, // Blue Grey
  ];

  static const Map<String, IconData> iconMap = {
    'work': Icons.work_outline_rounded,
    'home': Icons.home_outlined,
    'school': Icons.school_outlined,
    'fitness': Icons.fitness_center_outlined,
    'read': Icons.menu_book_outlined,
    'code': Icons.code_rounded,
    'shop': Icons.shopping_cart_outlined,
    'travel': Icons.flight_outlined,
    'food': Icons.restaurant_outlined,
    'coffee': Icons.local_cafe_outlined,
    'sleep': Icons.bed_outlined,
    'shower': Icons.shower_outlined,
    'commute': Icons.directions_bus_outlined,
    'game': Icons.videogame_asset_outlined,
    'clean': Icons.cleaning_services_outlined,
    'music': Icons.music_note_outlined,
    'art': Icons.palette_outlined,
    'meditate': Icons.self_improvement_outlined,
    'people': Icons.people_outline_rounded,
    'phone': Icons.phone_outlined,
    'mail': Icons.mail_outline_rounded,
    'doctor': Icons.medical_services_outlined,
    'pet': Icons.pets_outlined,
    'nature': Icons.park_outlined,
    'idea': Icons.lightbulb_outline_rounded,
    'finance': Icons.attach_money_rounded,
    'movie': Icons.movie_outlined,
    'date': Icons.favorite_border_rounded,
  };

  static IconData getIcon(String? name) {
    return iconMap[name] ?? Icons.circle;
  }
}
