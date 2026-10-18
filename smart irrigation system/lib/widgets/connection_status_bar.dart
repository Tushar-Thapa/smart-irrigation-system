import 'dart:async';
import 'package:flutter/material.dart';

/// Bottom or inline status bar indicating:
/// - "Last update: HH:MM:SS"
/// - Red "ESP32 offline" indicator if lastUpdate > 30 seconds
/// - Firebase connection status / reachability indicator
/// - Retry button when disconnected or error occurs
class ConnectionStatusBar extends StatefulWidget {
  final int? lastUpdate;
  final String formattedTime;
  final bool isOffline;
  final bool isFirebaseConnected;
  final VoidCallback? onRetry;

  const ConnectionStatusBar({
    super.key,
    required this.lastUpdate,
    required this.formattedTime,
    required this.isOffline,
    this.isFirebaseConnected = true,
    this.onRetry,
  });

  @override
  State<ConnectionStatusBar> createState() => _ConnectionStatusBarState();
}

class _ConnectionStatusBarState extends State<ConnectionStatusBar> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Periodically update the UI every second so "seconds ago" and offline threshold are dynamic
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  int? get _currentSecondsAgo {
    if (widget.lastUpdate == null || widget.lastUpdate! <= 0) return null;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final diff = nowMs - widget.lastUpdate!;
    if (diff < 0) return 0;
    return (diff / 1000).floor();
  }

  bool get _computedOffline {
    final sec = _currentSecondsAgo;
    if (sec == null) return true;
    return sec > 30;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isOffline = widget.isOffline || _computedOffline;
    final secondsAgo = _currentSecondsAgo;

    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.grey.shade100;
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade300;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Heartbeat / Pulse indicator icon
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOffline ? Colors.red : const Color(0xFF2E7D32),
                  boxShadow: [
                    BoxShadow(
                      color: (isOffline ? Colors.red : const Color(0xFF2E7D32)).withValues(alpha: 0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Last update text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Last update: ',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          widget.formattedTime,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (secondsAgo != null) ...[
                          Text(
                            ' (${secondsAgo}s ago)',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Status badge
              if (isOffline)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off_rounded, size: 14, color: Colors.red),
                      SizedBox(width: 4),
                      Text(
                        'ESP32 offline',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_rounded, size: 14, color: Color(0xFF2E7D32)),
                      SizedBox(width: 4),
                      Text(
                        'Online',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Firebase connection warning if Firebase server is unreachable
          if (!widget.isFirebaseConnected) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade900.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade700),
              ),
              child: Row(
                children: [
                  Icon(Icons.cloud_off, size: 16, color: Colors.amber.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Connecting to Firebase Realtime Database...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
                  if (widget.onRetry != null)
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: widget.onRetry,
                      child: const Text('Retry'),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
