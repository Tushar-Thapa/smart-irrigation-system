import 'package:flutter/material.dart';

/// Warning banner that displays urgent system alerts:
/// - Water tank low ("Water tank low - refill it. Pump is disabled.")
/// - Soil sensor fault ("Soil sensor problem. Pump is disabled.")
class WarningBanners extends StatelessWidget {
  final bool waterLow;
  final bool sensorOk;

  const WarningBanners({
    super.key,
    required this.waterLow,
    required this.sensorOk,
  });

  @override
  Widget build(BuildContext context) {
    final hasSensorFault = !sensorOk;
    if (!waterLow && !hasSensorFault) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (waterLow)
          _buildAlert(
            context: context,
            icon: Icons.water_drop_outlined,
            title: 'Water Tank Low',
            message: 'Water tank low - refill it. Pump is disabled.',
            isCritical: true,
          ),
        if (waterLow && hasSensorFault) const SizedBox(height: 8),
        if (hasSensorFault)
          _buildAlert(
            context: context,
            icon: Icons.sensors_off_outlined,
            title: 'Soil Sensor Fault',
            message: 'Soil sensor problem. Pump is disabled.',
            isCritical: false,
          ),
      ],
    );
  }

  Widget _buildAlert({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String message,
    required bool isCritical,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isCritical
        ? (isDark ? const Color(0xFF451A1A) : const Color(0xFFFFEBEE))
        : (isDark ? const Color(0xFF422006) : const Color(0xFFFFF7ED));

    final border = isCritical
        ? (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFFCDD2))
        : (isDark ? const Color(0xFF78350F) : const Color(0xFFFFEDD5));

    final accent = isCritical
        ? (isDark ? const Color(0xFFF87171) : const Color(0xFFD32F2F))
        : (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706));

    final text = isCritical
        ? (isDark ? const Color(0xFFFECACA) : const Color(0xFFB71C1C))
        : (isDark ? const Color(0xFFFEF3C7) : const Color(0xFF92400E));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                    color: text.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
