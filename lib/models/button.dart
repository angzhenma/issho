import 'package:flutter/material.dart';

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
    this.iconSize = 18,
    this.progressIndicatorSize = 20,
    this.progressIndicatorColor,
  });

  @override
  Widget build(BuildContext context) {
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: iconSize),
                const SizedBox(width: 6),
              ],
              Text(label),
            ],
          );

    final button = isOutlined
        ? OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            child: child,
          )
        : ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            child: child,
          );

    return isExpanded
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }

  Color _getTextColor(BuildContext context) {
    return isOutlined
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onPrimary;
  }
}