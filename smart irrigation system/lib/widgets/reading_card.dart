import 'package:flutter/material.dart';

/// Reading card for displaying sensor metrics: Temperature, Humidity, Soil Moisture, Water Tank Level.
/// Displays progress bar when [percentProgress] is provided (for Soil and Tank Level).
/// Shows "--" when value is null or missing.
/// Greys out content when [isGreyedOut] is true (e.g. when ESP32 is offline).
class ReadingCard extends StatelessWidget {
  final String title;
  final String? valueText;
  final String unit;
  final IconData icon;
  final Color accentColor;
  final double? percentProgress; // 0.0 to 100.0, or null
  final bool isGreyedOut;
  final String? subtitle;

  const ReadingCard({
    super.key,
    required this.title,
    required this.valueText,
    required this.unit,
    required this.icon,
    required this.accentColor,
    this.percentProgress,
    this.isGreyedOut = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveAccent = isGreyedOut ? (isDark ? Colors.grey.shade600 : Colors.grey.shade400) : accentColor;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    final String displayValue = (valueText != null && valueText!.isNotEmpty) ? valueText! : '--';

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isGreyedOut ? 0.6 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isGreyedOut
                ? (isDark ? Colors.white10 : Colors.black12)
                : effectiveAccent.withValues(alpha: 0.2),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header with Icon and Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: effectiveAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: effectiveAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: subtitleColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Value + Unit
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: isGreyedOut ? subtitleColor : textColor,
                  ),
                ),
                if (displayValue != '--' && unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ],
            ),

            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 11,
                  color: subtitleColor,
                ),
              ),
            ],

            // Optional Progress Bar for percentage values
            if (percentProgress != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (displayValue == '--')
                      ? 0.0
                      : (percentProgress!.clamp(0.0, 100.0) / 100.0),
                  minHeight: 7,
                  backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isGreyedOut ? Colors.grey : effectiveAccent,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
