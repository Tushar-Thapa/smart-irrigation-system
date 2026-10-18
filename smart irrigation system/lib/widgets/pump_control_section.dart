import 'package:flutter/material.dart';

/// Control section for changing irrigation operating mode:
/// - Auto
/// - Pump ON
/// - Pump OFF
/// Writes to `/irrigation/command`.
/// Highlights active mode from database `command`.
/// Confirms before triggering Pump ON.
/// Disables Pump ON when water is low or sensor has fault, with an explanatory note.
/// Includes the safety disclaimer: "The device enforces its own safety limits."
class PumpControlSection extends StatefulWidget {
  final String currentCommand; // "auto", "pump_on", "pump_off"
  final bool waterLow;
  final bool sensorOk;
  final bool isOffline;
  final Future<void> Function(String command) onCommandSelected;

  const PumpControlSection({
    super.key,
    required this.currentCommand,
    required this.waterLow,
    required this.sensorOk,
    required this.isOffline,
    required this.onCommandSelected,
  });

  @override
  State<PumpControlSection> createState() => _PumpControlSectionState();
}

class _PumpControlSectionState extends State<PumpControlSection> {
  bool _isWriting = false;

  bool get _isPumpBlocked => widget.waterLow || !widget.sensorOk;

  String? get _pumpBlockReason {
    if (widget.waterLow && !widget.sensorOk) {
      return 'Pump ON disabled: Water tank is low and sensor has fault.';
    } else if (widget.waterLow) {
      return 'Pump ON disabled: Water tank is low. Please refill.';
    } else if (!widget.sensorOk) {
      return 'Pump ON disabled: Soil moisture sensor fault detected.';
    }
    return null;
  }

  Future<void> _handleModeTap(String targetCommand) async {
    if (_isWriting) return;

    // Check if user clicked the already selected command
    if (widget.currentCommand == targetCommand) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mode is already set to ${targetCommand.toUpperCase().replaceAll('_', ' ')}.'),
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    // If target is pump_on and blocked, show alert and abort
    if (targetCommand == 'pump_on' && _isPumpBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(_pumpBlockReason ?? 'Pump cannot be started due to safety lock.'),
        ),
      );
      return;
    }

    // If target is pump_on, request user confirmation first
    if (targetCommand == 'pump_on') {
      final confirmed = await _showPumpOnConfirmationDialog();
      if (confirmed != true) return;
    }

    setState(() => _isWriting = true);

    try {
      await widget.onCommandSelected(targetCommand);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF2E7D32),
            content: Text('Command sent: ${targetCommand.toUpperCase().replaceAll('_', ' ')}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade800,
            content: Text('Failed to update command: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isWriting = false);
      }
    }
  }

  Future<bool?> _showPumpOnConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded, size: 40, color: Color(0xFFD97706)),
          title: const Text('Confirm Manual Pump ON'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to turn ON the irrigation pump manually?',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 12),
              Text(
                'Note: The ESP32 device will still enforce internal limits (such as the max 4-second cycle safety limit).',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Start Pump'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    final String normalizedCurrent = widget.currentCommand.toLowerCase().trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Icon(
                Icons.tune_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Pump Control Mode',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_isWriting)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Select desired mode. Device command is written to Firebase in real-time.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),

          // Three Mode Choice Buttons
          Row(
            children: [
              // 1. AUTO
              Expanded(
                child: _buildModeButton(
                  label: 'Auto',
                  icon: Icons.auto_mode_rounded,
                  commandValue: 'auto',
                  isSelected: normalizedCurrent == 'auto',
                  isDisabled: false,
                  activeColor: const Color(0xFF0284C7),
                ),
              ),
              const SizedBox(width: 8),

              // 2. PUMP ON
              Expanded(
                child: _buildModeButton(
                  label: 'Pump ON',
                  icon: Icons.play_arrow_rounded,
                  commandValue: 'pump_on',
                  isSelected: normalizedCurrent == 'pump_on',
                  isDisabled: _isPumpBlocked,
                  activeColor: const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 8),

              // 3. PUMP OFF
              Expanded(
                child: _buildModeButton(
                  label: 'Pump OFF',
                  icon: Icons.stop_rounded,
                  commandValue: 'pump_off',
                  isSelected: normalizedCurrent == 'pump_off',
                  isDisabled: false,
                  activeColor: const Color(0xFFDC2626),
                ),
              ),
            ],
          ),

          // If pump is blocked, show short reason
          if (_isPumpBlocked) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3F1D1D) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.red.shade400),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _pumpBlockReason ?? 'Pump ON is locked.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFFFCA5A5) : Colors.red.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Safety rule footnote
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                size: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'The device enforces its own safety limits.',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required IconData icon,
    required String commandValue,
    required bool isSelected,
    required bool isDisabled,
    required Color activeColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bg;
    Color border;
    Color contentColor;

    if (isDisabled) {
      bg = isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100;
      border = isDark ? Colors.white12 : Colors.grey.shade300;
      contentColor = isDark ? Colors.grey.shade600 : Colors.grey.shade400;
    } else if (isSelected) {
      bg = activeColor.withValues(alpha: isDark ? 0.25 : 0.12);
      border = activeColor;
      contentColor = isDark ? activeColor.withValues(alpha: 0.9) : activeColor;
    } else {
      bg = isDark ? const Color(0xFF0F172A) : Colors.grey.shade50;
      border = isDark ? Colors.white12 : Colors.grey.shade300;
      contentColor = isDark ? Colors.grey.shade300 : Colors.grey.shade700;
    }

    return InkWell(
      onTap: isDisabled || _isWriting ? null : () => _handleModeTap(commandValue),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: border,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: contentColor,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: contentColor,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: contentColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
