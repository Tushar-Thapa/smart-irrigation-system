import 'package:flutter/material.dart';

/// Top status bar showing whether the pump is physically running according
/// to the ESP32's reported `pumpOn` value.
class PumpStatusBar extends StatefulWidget {
  final bool isRunning;
  final bool isOffline;

  const PumpStatusBar({
    super.key,
    required this.isRunning,
    this.isOffline = false,
  });

  @override
  State<PumpStatusBar> createState() => _PumpStatusBarState();
}

class _PumpStatusBarState extends State<PumpStatusBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    if (widget.isRunning && !widget.isOffline) {
      _animController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PumpStatusBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRunning && !widget.isOffline) {
      if (!_animController.isAnimating) {
        _animController.repeat(reverse: true);
      }
    } else {
      _animController.stop();
      _animController.reset();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Pump status visuals:
    // Green when running, Grey when off
    final bool active = widget.isRunning && !widget.isOffline;
    
    final Color backgroundColor = active
        ? (isDark ? const Color(0xFF1B5E20) : const Color(0xFF2E7D32))
        : (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB));

    final Color foregroundColor = active
        ? Colors.white
        : (isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563));

    final Color badgeColor = active
        ? const Color(0xFF66BB6A)
        : (isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF));

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Transform.scale(
          scale: active ? _pulseAnimation.value : 1.0,
          child: child,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (active)
              BoxShadow(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.35),
                blurRadius: 14,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: active ? 0.3 : 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                active ? Icons.water_drop : Icons.water_drop_outlined,
                color: foregroundColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'PUMP STATUS (LIVE ESP32)',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w600,
                      color: foregroundColor.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    active ? 'Pump RUNNING' : 'Pump OFF',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: foregroundColor,
                    ),
                  ),
                ],
              ),
            ),
            // Status pill badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: active
                    ? Colors.white.withValues(alpha: 0.2)
                    : (isDark ? Colors.black26 : Colors.white60),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: foregroundColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? const Color(0xFF81C784) : const Color(0xFF9E9E9E),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    active ? 'ACTIVE' : 'IDLE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: foregroundColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
