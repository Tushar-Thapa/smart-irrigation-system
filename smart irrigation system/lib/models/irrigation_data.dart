import 'package:intl/intl.dart';

/// Represents the data payload received from the ESP32 via Firebase Realtime Database
/// under the `/irrigation` node.
class IrrigationData {
  final double? temperature;
  final double? humidity;
  final double? soilPercent;
  final double? waterPercent;
  final bool waterLow;
  final bool pumpOn;
  final bool sensorOk;
  final int? lastUpdate;
  final String command;

  const IrrigationData({
    this.temperature,
    this.humidity,
    this.soilPercent,
    this.waterPercent,
    this.waterLow = false,
    this.pumpOn = false,
    this.sensorOk = true,
    this.lastUpdate,
    this.command = 'auto',
  });

  /// Factory constructor to safely parse data from a Firebase DataSnapshot value map.
  /// Handles missing keys, type casting from numbers/strings, and nulls safely.
  factory IrrigationData.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) {
      return const IrrigationData();
    }

    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    bool parseBool(dynamic value, {bool defaultValue = false}) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final lower = value.toLowerCase().trim();
        return lower == 'true' || lower == '1';
      }
      return defaultValue;
    }

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return IrrigationData(
      temperature: parseDouble(map['temperature']),
      humidity: parseDouble(map['humidity']),
      soilPercent: parseDouble(map['soilPercent']),
      waterPercent: parseDouble(map['waterPercent']),
      waterLow: parseBool(map['waterLow'], defaultValue: false),
      pumpOn: parseBool(map['pumpOn'], defaultValue: false),
      sensorOk: parseBool(map['sensorOk'], defaultValue: true),
      lastUpdate: parseInt(map['lastUpdate']),
      command: (map['command'] as String?)?.trim().toLowerCase() ?? 'auto',
    );
  }

  /// Calculates whether the ESP32 is offline (no update received in the last 30 seconds).
  bool get isOffline {
    if (lastUpdate == null || lastUpdate! <= 0) return true;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final diffMs = nowMs - lastUpdate!;
    // Consider offline if older than 30,000 milliseconds (30 seconds)
    return diffMs > 30000;
  }

  /// Formatted last update time as HH:mm:ss. Returns "--:--:--" if unavailable.
  String get formattedLastUpdate {
    if (lastUpdate == null || lastUpdate! <= 0) return '--:--:--';
    try {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(lastUpdate!);
      return DateFormat('HH:mm:ss').format(dateTime);
    } catch (_) {
      return '--:--:--';
    }
  }

  /// Seconds elapsed since the last update
  int? get secondsAgo {
    if (lastUpdate == null || lastUpdate! <= 0) return null;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final diffMs = nowMs - lastUpdate!;
    if (diffMs < 0) return 0;
    return (diffMs / 1000).floor();
  }

  /// Returns true if pump manual activation is disabled due to safety hazards.
  bool get isPumpBlocked => waterLow || !sensorOk;

  /// Explanatory reason when pump cannot be activated manually
  String? get pumpBlockReason {
    if (waterLow && !sensorOk) {
      return 'Low water tank & soil sensor fault';
    } else if (waterLow) {
      return 'Water tank is low - refill tank';
    } else if (!sensorOk) {
      return 'Soil sensor problem';
    }
    return null;
  }

  IrrigationData copyWith({
    double? temperature,
    double? humidity,
    double? soilPercent,
    double? waterPercent,
    bool? waterLow,
    bool? pumpOn,
    bool? sensorOk,
    int? lastUpdate,
    String? command,
  }) {
    return IrrigationData(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      soilPercent: soilPercent ?? this.soilPercent,
      waterPercent: waterPercent ?? this.waterPercent,
      waterLow: waterLow ?? this.waterLow,
      pumpOn: pumpOn ?? this.pumpOn,
      sensorOk: sensorOk ?? this.sensorOk,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      command: command ?? this.command,
    );
  }
}
