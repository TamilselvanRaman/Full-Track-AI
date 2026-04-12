// lib/widgets/common/selection_button.dart
import 'package:flutter/material.dart';
import '../../core/constants.dart';

class SelectionButton extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const SelectionButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 70,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: selected
                ? const Color(AppConstants.primaryColorValue).withOpacity(0.12)
                : const Color(AppConstants.surfaceColorValue),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? const Color(AppConstants.primaryColorValue)
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected
                      ? const Color(AppConstants.primaryColorValue)
                      : Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected
                        ? const Color(AppConstants.primaryColorValue).withOpacity(0.7)
                        : Colors.white38,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
