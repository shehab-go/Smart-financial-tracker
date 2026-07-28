import 'package:flutter/material.dart';

enum FinancialInsightType {
  warning, // Red/Orange for alerts & budget limit
  increase, // Orange for spending increase
  info, // Blue for general info & forecast
  success, // Green for saving & budget within limit
}

class FinancialInsight {
  final String id;
  final String title;
  final String description;
  final FinancialInsightType type;
  final double? percentageChange;
  final String? category;
  final IconData icon;
  final Color primaryColor;
  final VoidCallback? onTapAction;

  FinancialInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.percentageChange,
    this.category,
    required this.icon,
    required this.primaryColor,
    this.onTapAction,
  });
}
