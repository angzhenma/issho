// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

// Programmer Name: Mr. Ibrahim Azaan Mauroof
// Program Name: pages/auth/login.dart
// Program Description: Reusable button class for uniform styling.
// First Written on: Sunday, 6-July-2025
// Last Modified on: Monday, 20-July-2025

class AppButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool isOutlined;
  final bool isExpanded;
  final bool isLoading;
  final double? iconSize;
  final double? progressIndicatorSize;
  final Color? progressIndicatorColor;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isOutlined = false,
    this.isExpanded = false,
    this.isLoading = false,
    this.iconSize = 20,
    this.progressIndicatorSize = 20,
    this.progressIndicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = isLoading
        ? SizedBox(
            width: progressIndicatorSize,
            height: progressIndicatorSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                progressIndicatorColor ?? _getTextColor(context),
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: iconSize, color: _getTextColor(context)),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _getTextColor(context),
                ),
              ),
            ],
          );

    final button = isOutlined
        ? OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: _outlinedStyle(context),
            child: child,
          )
        : ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: _elevatedStyle(context),
            child: child,
          );

    return isExpanded
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }

  ButtonStyle _elevatedStyle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ElevatedButton.styleFrom(
      elevation: 3,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      overlayColor: colorScheme.primary.withOpacity(0.1),
    );
  }

  ButtonStyle _outlinedStyle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return OutlinedButton.styleFrom(
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      foregroundColor: colorScheme.primary,
      side: BorderSide(color: colorScheme.primary, width: 1.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      overlayColor: colorScheme.primary.withOpacity(0.05),
    );
  }

  Color _getTextColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return isOutlined ? colorScheme.primary : colorScheme.onPrimary;
  }
}
