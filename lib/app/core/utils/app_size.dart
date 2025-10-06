import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppSize {
  static double h1 = 24;
  static double h2 = 16;
  static double h3 = 14;
  static double h4 = 12;
  static double h5 = 10;
  static double h6 = 8;

  // Method to get screen height percentages dynamically
  static double getHeight(double percentage) {
    return Get.height * (percentage / 100);
  }

  // Method to get screen width percentages dynamically
  static double getWidth(double percentage) {
    return Get.width * (percentage / 100);
  }

  // Example getter methods for predefined percentages
  static double get h7 => getHeight(7);
  static double get h8 => getHeight(8);
  static double get h9 => getHeight(9);
  static double get h10 => getHeight(10);

  static double get w1 => getWidth(1);
  static double get w2 => getWidth(2);
  static double get w3 => getWidth(3);
  static double get w4 => getWidth(4);
  static double get w5 => getWidth(5);
  static double get w6 => getWidth(6);
  static double get w7 => getWidth(7);
  static double get w8 => getWidth(8);
  static double get w9 => getWidth(9);
  static double get w10 => getWidth(10);
}

// Utility function to generate user initials from name
String getUserInitials(String? name) {
  if (name == null || name.trim().isEmpty) {
    return 'U';
  }
  
  final nameParts = name.trim().split(' ');
  if (nameParts.isEmpty) {
    return 'U';
  }
  
  if (nameParts.length == 1) {
    return nameParts[0].substring(0, 1).toUpperCase();
  }
  
  return '${nameParts[0].substring(0, 1)}${nameParts[1].substring(0, 1)}'.toUpperCase();
}

// Utility function to get a color based on user initials for consistent avatar colors
Color getAvatarColor(String initials) {
  final colors = [
    const Color(0xFF0095F6), // Blue
    const Color(0xFF00C851), // Green
    const Color(0xFFFF6B35), // Orange
    const Color(0xFF9C27B0), // Purple
    const Color(0xFFE91E63), // Pink
    const Color(0xFF795548), // Brown
    const Color(0xFF607D8B), // Blue Grey
    const Color(0xFF3F51B5), // Indigo
  ];
  
  // Use initials to consistently pick a color
  int index = 0;
  for (int i = 0; i < initials.length; i++) {
    index += initials.codeUnitAt(i);
  }
  return colors[index % colors.length];
}
