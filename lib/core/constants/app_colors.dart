import 'package:flutter/material.dart';

class AppColors {
  // Brand / Primary
  static const Color primary = Color(0xFF1A73E8); // Google blue
  static const Color primaryDark = Color(0xFF1557B0);
  static const Color primaryLight = Color(0xFFE8F0FE);
  static const Color secondary = Color(0xFF0D9488); // Teal
  static const Color secondaryLight = Color(0xFFCCFBF1);

  // Surface & Background
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF1F3F4);
  static const Color outline = Color(0xFFDADCE0);
  static const Color outlineLight = Color(0xFFECEFF1);

  // Status Colors
  static const Color confirmed = Color(0xFF1E8E3E); // Google Green
  static const Color confirmedLight = Color(0xFFE6F4EA);
  static const Color followUp = Color(0xFFF9AB00); // Amber / Yellow
  static const Color followUpLight = Color(0xFFFEF7E0);
  static const Color quotationSent = Color(0xFF9334E6); // Purple
  static const Color quotationSentLight = Color(0xFFF3E8FD);
  static const Color contacted = Color(0xFF1A73E8); // Blue
  static const Color contactedLight = Color(0xFFE8F0FE);
  static const Color newEnquiry = Color(0xFFEA4335); // Coral / Red
  static const Color newEnquiryLight = Color(0xFFFCE8E6);
  static const Color cancelled = Color(0xFF5F6368); // Grey
  static const Color cancelledLight = Color(0xFFF1F3F4);
  static const Color lost = Color(0xFFD93025); // Dark Red
  static const Color lostLight = Color(0xFFFCE8E6);

  // Text Colors
  static const Color textPrimary = Color(0xFF202124);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color textMuted = Color(0xFF80868B);

  // Calendar Event Chip Colors
  static const List<Color> eventPalette = [
    Color(0xFF039BE5), // Peacock blue
    Color(0xFF0B8043), // Basil green
    Color(0xFF7986CB), // Lavender
    Color(0xFF8E24AA), // Grape purple
    Color(0xFFE67C73), // Flamingo coral
    Color(0xFFF6BF26), // Banana yellow
    Color(0xFF3F51B5), // Indigo
    Color(0xFFD81B60), // Ruby
  ];

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return confirmed;
      case 'follow-up':
      case 'follow-up required':
      case 'followup':
        return followUp;
      case 'quotation sent':
      case 'quotation':
        return quotationSent;
      case 'contacted':
        return contacted;
      case 'new':
      case 'new enquiry':
        return newEnquiry;
      case 'lost':
        return lost;
      case 'cancelled':
      case 'closed':
        return cancelled;
      case 'in-progress':
        return primary;
      case 'completed':
        return confirmed;
      default:
        return textSecondary;
    }
  }

  static Color getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return confirmedLight;
      case 'follow-up':
      case 'follow-up required':
      case 'followup':
        return followUpLight;
      case 'quotation sent':
      case 'quotation':
        return quotationSentLight;
      case 'contacted':
        return contactedLight;
      case 'new':
      case 'new enquiry':
        return newEnquiryLight;
      case 'lost':
        return lostLight;
      case 'cancelled':
      case 'closed':
        return cancelledLight;
      case 'in-progress':
        return primaryLight;
      case 'completed':
        return confirmedLight;
      default:
        return surfaceVariant;
    }
  }
}

