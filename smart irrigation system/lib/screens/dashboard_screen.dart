import 'dart:async';
import 'package:flutter/material.dart';
import '../models/irrigation_data.dart';
import '../services/irrigation_service.dart';
import '../widgets/pump_status_bar.dart';
import '../widgets/reading_card.dart';
import '../widgets/warning_banner.dart';
import '../widgets/pump_control_section.dart';
import '../widgets/connection_status_bar.dart';

/// Main single-screen dashboard for Smart Irrigation system.
/// Uses Material 3 design, green theme, and supports light and dark modes.
class DashboardScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const DashboardScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final IrrigationService _service;
  Stream<IrrigationData>? _dataStream;
  Stream<bool>? _connectionStream;
  Key _streamKey = UniqueKey();
  Timer? _localClockTimer;

  @override
  void initState() {
    super.initState();
    _service = IrrigationService();
    _initializeStreams();

    // Rebuild every second so time-based offline calculations update live
    _localClockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _initializeStreams() {
    _dataStream = _service.irrigationStream;
    _connectionStream = _service.connectionStream;
  }

  void _retryConnection() {
    setState(() {
      _streamKey = UniqueKey();
      _initializeStreams();
    });
  }

  @override
  void dispose() {
    _localClockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.eco,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Smart Irrigation',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: widget.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            onPressed: widget.onToggleTheme,
          ),
          IconButton(
            tooltip: 'Refresh Connection',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _retryConnection,
          ),
        ],
        elevation: 0,
      ),
      body: StreamBuilder<bool>(
        stream: _connectionStream,
        initialData: true,
        builder: (context, connSnapshot) {
          final isFirebaseConnected = connSnapshot.data ?? true;

          return StreamBuilder<IrrigationData>(
            key: _streamKey,
            stream: _dataStream,
            builder: (context, snapshot) {
              // Error state (e.g. Firebase unreachable or permission error)
              if (snapshot.hasError) {
                return _buildErrorView(snapshot.error.toString());
              }

              // Loading state (waiting for initial Firebase payload)
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return _buildLoadingView();
              }

              final data = snapshot.data ?? const IrrigationData();
              final isOffline = data.isOffline;

              return RefreshIndicator(
                color: theme.colorScheme.primary,
                onRefresh: () async {
                  _retryConnection();
                  await Future.delayed(const Duration(milliseconds: 600));
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Pump Status Bar (top, large, always visible)
                      PumpStatusBar(
                        isRunning: data.pumpOn,
                        isOffline: isOffline,
                      ),
                      const SizedBox(height: 16),

                      // 3. Warning Banners (shown only when relevant)
                      WarningBanners(
                        waterLow: data.waterLow,
                        sensorOk: data.sensorOk,
                      ),
                      if (data.waterLow || !data.sensorOk) const SizedBox(height: 16),

                      // 2. Four Reading Cards (Grid / 2x2 layout)
                      _buildReadingsGrid(data, isOffline),
                      const SizedBox(height: 16),

                      // 4. Pump Control Section (Mode Selector)
                      PumpControlSection(
                        currentCommand: data.command,
                        waterLow: data.waterLow,
                        sensorOk: data.sensorOk,
                        isOffline: isOffline,
                        onCommandSelected: (cmd) => _service.sendCommand(cmd),
                      ),
                      const SizedBox(height: 16),

                      // 5. Connection Status Bar
                      ConnectionStatusBar(
                        lastUpdate: data.lastUpdate,
                        formattedTime: data.formattedLastUpdate,
                        isOffline: isOffline,
                        isFirebaseConnected: isFirebaseConnected,
                        onRetry: _retryConnection,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildReadingsGrid(IrrigationData data, bool isOffline) {
    return Column(
      children: [
        Row(
          children: [
            // Temperature Card
            Expanded(
              child: ReadingCard(
                title: 'Temperature',
                valueText: data.temperature?.toStringAsFixed(1),
                unit: '°C',
                icon: Icons.thermostat_outlined,
                accentColor: const Color(0xFFEF4444),
                isGreyedOut: isOffline,
              ),
            ),
            const SizedBox(width: 12),
            // Air Humidity Card
            Expanded(
              child: ReadingCard(
                title: 'Air Humidity',
                valueText: data.humidity?.toStringAsFixed(0),
                unit: '%',
                icon: Icons.cloud_outlined,
                accentColor: const Color(0xFF0284C7),
                isGreyedOut: isOffline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Soil Moisture Card
            Expanded(
              child: ReadingCard(
                title: 'Soil Moisture',
                valueText: data.soilPercent?.toStringAsFixed(0),
                unit: '%',
                icon: Icons.water_drop_outlined,
                accentColor: const Color(0xFF16A34A),
                percentProgress: data.soilPercent,
                subtitle: data.sensorOk ? 'Sensor OK' : 'Sensor Fault',
                isGreyedOut: isOffline,
              ),
            ),
            const SizedBox(width: 12),
            // Water Tank Level Card
            Expanded(
              child: ReadingCard(
                title: 'Water Tank Level',
                valueText: data.waterPercent?.toStringAsFixed(0),
                unit: '%',
                icon: Icons.waves_outlined,
                accentColor: const Color(0xFF06B6D4),
                percentProgress: data.waterPercent,
                subtitle: data.waterLow ? 'Low Level' : 'Normal Level',
                isGreyedOut: isOffline,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Connecting to Firebase Realtime Database...',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 6),
          Text(
            'Node: /irrigation (Singapore Region)',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 56, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Database Connection Error',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry Connection'),
              onPressed: _retryConnection,
            ),
          ],
        ),
      ),
    );
  }
}
