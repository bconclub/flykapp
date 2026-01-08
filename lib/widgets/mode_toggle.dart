import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ModeToggle extends StatelessWidget {
  final bool isResearchMode;
  final ValueChanged<bool> onToggle;

  const ModeToggle({
    super.key,
    required this.isResearchMode,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Just capture',
            style: TextStyle(
              color: !isResearchMode ? AppTheme.primaryColor : AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: !isResearchMode ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: isResearchMode,
            onChanged: onToggle,
            activeColor: AppTheme.primaryColor,
          ),
          const SizedBox(width: 12),
          Text(
            'Capture + act',
            style: TextStyle(
              color: isResearchMode ? AppTheme.primaryColor : AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: isResearchMode ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

