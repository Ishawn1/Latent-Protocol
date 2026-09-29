import 'package:flutter/material.dart';

/// Health status of a plot
enum PlotHealth { healthy, needsAttention, critical }

/// Severity level for farm alerts
enum AlertSeverity { info, warning, critical }

/// Operational / Health status of a virtual farm zone
enum ZoneHealthStatus {
  healthy,
  stress,
  diseaseWarning,
  critical,
  pendingScout,
}

/// Represents a virtual grid zone in the farm (e.g., A1, B2)
class VirtualZone {
  final String id;
  final String name;
  final ZoneHealthStatus status;
  final double soilMoisturePercent;
  final double tempC;
  final String lastScoutedTime;
  final String? activeConcern;
  final bool hasHardwareNode;
  final String cropVariety;

  const VirtualZone({
    required this.id,
    required this.name,
    required this.status,
    required this.soilMoisturePercent,
    required this.tempC,
    required this.lastScoutedTime,
    this.activeConcern,
    this.hasHardwareNode = false,
    this.cropVariety = 'Bhagwa',
  });

  Color get statusColor {
    switch (status) {
      case ZoneHealthStatus.healthy:
        return const Color(0xFF16A34A); // Green
      case ZoneHealthStatus.stress:
        return const Color(0xFFEAB308); // Yellow
      case ZoneHealthStatus.diseaseWarning:
        return const Color(0xFFEA580C); // Orange
      case ZoneHealthStatus.critical:
        return const Color(0xFFDC2626); // Red
      case ZoneHealthStatus.pendingScout:
        return const Color(0xFF94A3B8); // Slate/Grey
    }
  }

  String get statusLabel {
    switch (status) {
      case ZoneHealthStatus.healthy:
        return 'Healthy';
      case ZoneHealthStatus.stress:
        return 'Water Stress';
      case ZoneHealthStatus.diseaseWarning:
        return 'Disease Risk';
      case ZoneHealthStatus.critical:
        return 'Critical Alert';
      case ZoneHealthStatus.pendingScout:
        return 'Pending Scout';
    }
  }
}

/// Represents a farm plot with crop and status information.
class Plot {
  final String name;
  final String crop;
  final String variety;
  final double areaAcres;
  final String plantedDate;
  final PlotHealth health;
  final String? lastIrrigation;
  final int? harvestDaysRemaining;
  final List<VirtualZone> zones;

  const Plot({
    required this.name,
    required this.crop,
    this.variety = 'Bhagwa',
    required this.areaAcres,
    required this.plantedDate,
    required this.health,
    this.lastIrrigation,
    this.harvestDaysRemaining,
    this.zones = const [],
  });

  /// Default demo Pomegranate orchard adhering to SIH 2026 specification
  static const demoOrchard = Plot(
    name: 'Bhagwa Orchard Block 1',
    crop: 'Pomegranate',
    variety: 'Bhagwa (Sindhuri)',
    areaAcres: 3.5,
    plantedDate: '12 Jan 2024',
    health: PlotHealth.healthy,
    lastIrrigation: 'Yesterday (Drip)',
    harvestDaysRemaining: 65,
    zones: [
      VirtualZone(
        id: 'A1',
        name: 'Zone A1 (Hub Node 1)',
        status: ZoneHealthStatus.healthy,
        soilMoisturePercent: 52.0,
        tempC: 28.5,
        lastScoutedTime: '10 min ago',
        hasHardwareNode: true,
      ),
      VirtualZone(
        id: 'A2',
        name: 'Zone A2 (North Row)',
        status: ZoneHealthStatus.healthy,
        soilMoisturePercent: 49.0,
        tempC: 28.8,
        lastScoutedTime: '2 hrs ago',
      ),
      VirtualZone(
        id: 'B1',
        name: 'Zone B1 (Center East)',
        status: ZoneHealthStatus.diseaseWarning,
        soilMoisturePercent: 38.0,
        tempC: 29.2,
        lastScoutedTime: 'Today 09:15 AM',
        activeConcern: 'Alternaria Leaf Spot suspected',
      ),
      VirtualZone(
        id: 'B2',
        name: 'Zone B2 (Center West)',
        status: ZoneHealthStatus.stress,
        soilMoisturePercent: 28.0,
        tempC: 30.1,
        lastScoutedTime: 'Yesterday',
        activeConcern: 'Soil moisture low (<30%)',
      ),
      VirtualZone(
        id: 'C1',
        name: 'Zone C1 (South East)',
        status: ZoneHealthStatus.healthy,
        soilMoisturePercent: 55.0,
        tempC: 28.1,
        lastScoutedTime: '3 days ago',
      ),
      VirtualZone(
        id: 'C2',
        name: 'Zone C2 (Drainage End)',
        status: ZoneHealthStatus.pendingScout,
        soilMoisturePercent: 46.0,
        tempC: 28.4,
        lastScoutedTime: 'Pending Optical Scout',
      ),
    ],
  );
}

/// Sensor reading from a Tier-1 ESP32 node.
class SensorReading {
  final double temperatureC;
  final int humidityPercent;
  final int soilMoisturePercent;
  final double dsv;
  final bool leafWetness;
  final bool nodeConnected;
  final String nodeName;

  const SensorReading({
    required this.temperatureC,
    required this.humidityPercent,
    required this.soilMoisturePercent,
    required this.dsv,
    required this.leafWetness,
    required this.nodeConnected,
    this.nodeName = 'Node 1',
  });

  /// Demo data for UI display while hardware is WIP.
  static const demo = SensorReading(
    temperatureC: 28,
    humidityPercent: 65,
    soilMoisturePercent: 42,
    dsv: 0.2,
    leafWetness: false,
    nodeConnected: true,
  );
}

/// An advisory alert displayed on the Advisory screen.
class FarmAlert {
  final IconData icon;
  final Color iconColor;
  final String titleKey;
  final String descriptionKey;
  final String timeAgo;
  final AlertSeverity severity;

  const FarmAlert({
    required this.icon,
    required this.iconColor,
    required this.titleKey,
    required this.descriptionKey,
    required this.timeAgo,
    required this.severity,
  });
}
