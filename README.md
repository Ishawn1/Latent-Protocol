# SmartKheti 🌱

> **Edge-AI Smart Farming Assistant** — Real-time crop health monitoring, disease detection, and irrigation management for pomegranate farmers, powered by on-device YOLO26n inference and an ESP32-S3 IoT field unit.

---

## Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [System Architecture](#system-architecture)
- [Hardware — ESP32-S3 Field Unit](#hardware--esp32-s3-field-unit)
- ![SmartKheti ESP32-S3 Field Unit](assets/Smartkheti-Hardware.png)
  - [Components](#components)
  - [Wiring Reference](#wiring-reference)
  - [Flashing the Firmware](#flashing-the-firmware)
- [AI Models](#ai-models)
- [Flutter App](#flutter-app)
  - [Prerequisites](#prerequisites)
  - [Setup & Run](#setup--run)
  - [Environment Variables](#environment-variables)
- [Project Structure](#project-structure)
- [Configuration](#configuration)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

SmartKheti is an open-source, edge-first precision agriculture platform built for small and marginal farmers in India. It combines a **Flutter mobile app** with an **ESP32-S3 N16R8 IoT field unit** to deliver:

- **Sub-millisecond on-chip AI diagnostics** — a hand-crafted 3-layer neural network runs entirely in C++ inside the ESP32, predicting water stress and crop inspection risk from live sensor data with **zero cloud dependency**.
- **On-device YOLO26n vision models** — four INT8-quantised TFLite models run directly on Android (no server required) to detect pomegranate diseases, pests, and growth stages.
- **Live microclimate monitoring** — DHT22 air sensors, RS485 Modbus soil probes (moisture / temperature / EC), and a rain sensor stream real-time telemetry to the app via a Wi-Fi Access Point.

The platform is designed to work in areas with **poor or no internet connectivity**.

---

## Key Features

| Feature | Details |
|---|---|
| 🔬 **Disease Detection** | YOLO26n INT8 model detects Alternaria, Fungal Spot, Bacterial Blight, and Healthy leaf states in real time |
| 🐛 **Pest Detection** | YOLO26s INT8 universal pest model covers 9 classes: grubs, red spider, aphids, locusts, thrips, whitefly, *Prodenia litura*, mango hopper, jassids |
| 🌿 **Growth Stage Monitoring** | 5-class phenological model: bud → flower → early-fruit → mid-growth → mature |
| 💧 **Smart Irrigation** | Soil moisture, temperature, and EC from RS485 SN-3000 probe; AI-driven irrigation schedule recommendations |
| 🧠 **On-Chip Edge AI** | 3-layer MLP (6→16→8→2, sigmoid output) running entirely on ESP32-S3; predicts water stress and crop anomaly risk in ~0.02 ms |
| 📡 **IoT Telemetry** | ESP32-S3 acts as a Wi-Fi AP; app polls `/data` with token authentication every 4.5 seconds |
| 🔔 **Smart Alerts** | Android system-tray notifications (high-priority channel) for irrigation-needed and inspection-required events, with 15-minute anti-spam cooldown persisted across app restarts |
| 🌤️ **Weather Integration** | Live weather via WeatherAPI.com with IP-based auto-location; physics-based diurnal fallback model when offline |
| 📊 **Farm Analytics** | Historical sensor trends, field-level performance, and yield-risk insight dashboard |
| 🗺️ **Farm Map** | Visual field mapping and zone management |
| 📋 **Task Management** | Seasonal farm task tracking |
| 🌐 **Multilingual** | Flutter localisation (l10n) support |

---

## System Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                        Android App (Flutter)                     │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────────────┐   │
│  │  Home Screen │  │  Irrigation  │  │  Disease Detection  │   │
│  │  (telemetry) │  │  Screen      │  │  (YOLO Live/Static) │   │
│  └──────┬───────┘  └──────┬───────┘  └──────────┬──────────┘   │
│         └─────────────────┼──────────────────────┘              │
│                           ▼                                      │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │           Esp32BackendService (ChangeNotifier)             │  │
│  │  • Parses JSON telemetry from EspApPollingService          │  │
│  │  • Hardware watchdog (15 s timeout)                        │  │
│  │  • Valve actuation state machine                           │  │
│  │  • Triggers AlertNotificationService on AI alerts          │  │
│  └──────────────┬─────────────────────────────────────────────┘  │
│                 │                                                  │
│  ┌──────────────▼────────┐   ┌────────────────────────────────┐  │
│  │  EspApPollingService  │   │  WeatherApiService             │  │
│  │  GET /data @ ESP32 AP │   │  WeatherAPI.com + diurnal      │  │
│  │  every 4.5 s          │   │  fallback model                │  │
│  └──────────────┬────────┘   └────────────────────────────────┘  │
│                 ▼                                                  │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │  AlertNotificationService (flutter_local_notifications)  │    │
│  │  High-priority Android channel · 15-min cooldown         │    │
│  └──────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────┘
                  Wi-Fi AP  (192.168.4.1)
┌──────────────────────────────────────────────────────────────────┐
│                  ESP32-S3 N16R8 Field Unit                       │
│                                                                  │
│  ┌─────────────┐  ┌─────────────────────┐  ┌───────────────┐   │
│  │  DHT22      │  │  SN-3000 Soil Probe │  │  Rain / Water │   │
│  │  Temp & Hum │  │  (RS485 Modbus RTU) │  │  Sensor       │   │
│  └──────┬──────┘  └──────┬──────────────┘  └──────┬────────┘   │
│         └───────────────┬┘                          │           │
│                         └──────────────┬─────────────┘          │
│                                        ▼                         │
│                  SmartKhetiAI.h — On-Chip Inference              │
│             6-feature MLP  →  Water Stress Probability           │
│                             →  Crop Inspection Risk              │
│                                        ▼                         │
│                  WebServer (port 80)                             │
│                  GET /      → HTML dashboard                     │
│                  GET /data  → JSON telemetry + AI predictions    │
└──────────────────────────────────────────────────────────────────┘
```

---

## Hardware — ESP32-S3 Field Unit

### Components

| Component | Specification |
|---|---|
| Microcontroller | ESP32-S3 N16R8 (16 MB Flash, 8 MB PSRAM) |
| Air Sensor | DHT22 (Temperature + Humidity) |
| Soil Probe | SN-3000 RS485 Modbus RTU (Moisture / Temperature / EC) |
| Rain Sensor | Digital water-detection module |

**Required Arduino Libraries** (install via Arduino IDE Library Manager):
- `DHT sensor library` by Adafruit
- `ModbusMaster` by Doc Walker
- `ArduinoJson` by Benoit Blanchon

### Wiring Reference

| Signal | ESP32-S3 GPIO |
|---|---|
| DHT22 Data | GPIO 4 |
| Rain Sensor | GPIO 5 |
| RS485 RX | GPIO 17 |
| RS485 TX | GPIO 18 |

> **Soil Sensor:** 4800 bps, 8N1, Modbus Device ID = 1

### Flashing the Firmware

1. Install [Arduino IDE 2.x](https://www.arduino.cc/en/software) with the **ESP32 board package** (Espressif Systems).
2. Install the three libraries listed above.
3. Open `firmware/smartkheti_field_unit/smartkheti_field_unit.ino`.
4. Select **Board → ESP32S3 Dev Module**, Flash Size `16MB`, PSRAM `OPI PSRAM`.
5. **Before uploading**, update credentials in the sketch (see [Configuration](#configuration)).
6. Click **Upload**.

> ⚠️ **Before deploying to any field:** change the default AP password and API token in the firmware. Never deploy a device with factory-default credentials.

---

## AI Models

All four models are INT8-quantised TFLite files placed in `assets/models/`. They are tracked with **Git LFS** (see `.gitattributes`).

| File | Architecture | Input | Classes | Use Case |
|---|---|---|---|---|
| `pomegranate_yolo26n_416_int8.tflite` | YOLO26n | 416×416 | 4 (disease) | Real-time disease detection |
| `pomegranate_yolo26n_int8.tflite` | YOLO26n | — | 4 (disease) | Static photo analysis |
| `pest_yolo26s_int8.tflite` | YOLO26s | 640×640 | 9 (pests) | Universal pest detection |
| `pomegranate_growth_yolo26n_640_int8.tflite` | YOLO26n | 640×640 | 5 (growth) | Phenological stage tracking |

**Disease classes:** Alternaria · Fungal Spot · Bacterial Blight · Healthy  
**Pest classes:** Grub · Red Spider · Aphids · Locustoidea · Thrips · Whitefly · *Prodenia litura* · Mango Hopper · Jassids  
**Growth stages:** Bud → Flower → Early-Fruit → Mid-Growth → Mature

> **Git LFS required** — Run `git lfs install` before cloning, or the model files will be checked out as LFS pointer files only.

---

## Flutter App

### Prerequisites

| Requirement | Version |
|---|---|
| Flutter SDK | ≥ 3.6.0 |
| Dart SDK | ≥ 3.6.0 |
| Android target | API 26+ (Android 8.0) |
| Target device | Physical Android device recommended (camera + Wi-Fi AP required) |

### Setup & Run

```bash
# 1. Ensure Git LFS is installed (required for TFLite model files)
git lfs install

# 2. Clone the repository
git clone https://github.com/<your-username>/smartkheti.git
cd smartkheti

# 3. Install Flutter dependencies
flutter pub get

# 4. Run on a connected Android device
#    Optionally pass your own WeatherAPI key (free at weatherapi.com)
flutter run --dart-define=WEATHER_API_KEY=<your_key>
```


## Project Structure

```
smartkheti/
├── .gitattributes                     # Git LFS tracking for *.tflite models
├── assets/
│   └── models/                        # INT8 TFLite YOLO models (Git LFS)
│       ├── pomegranate_yolo26n_416_int8.tflite
│       ├── pomegranate_yolo26n_int8.tflite
│       ├── pest_yolo26s_int8.tflite
│       └── pomegranate_growth_yolo26n_640_int8.tflite
├── firmware/
│   └── smartkheti_field_unit/
│       ├── smartkheti_field_unit.ino  # ESP32-S3 main sketch
│       └── SmartKhetiAI.h             # On-chip MLP inference (pure C++)
├── lib/
│   ├── main.dart                      # App entry point & navigation
│   ├── l10n/                          # Localisation ARB files
│   ├── models/
│   │   ├── ai_model_registry.dart     # YOLO model catalogue & config
│   │   ├── detection_models.dart
│   │   ├── disease_models.dart        # Disease class definitions
│   │   ├── esp32_telemetry.dart       # Telemetry data model & JSON parsing
│   │   ├── farm_models.dart
│   │   ├── growth_models.dart         # Phenological stage definitions
│   │   ├── pest_models.dart           # Pest class definitions
│   │   └── task_models.dart
│   ├── screens/
│   │   ├── home_screen.dart           # Dashboard with live telemetry
│   │   ├── irrigation_screen.dart     # Smart irrigation controls
│   │   ├── farm_analytics_screen.dart # Historical charts & trends
│   │   ├── farm_map_screen.dart       # Visual field mapping
│   │   ├── advisory_screen.dart       # AI-generated crop advisories
│   │   ├── my_farm_screen.dart        # Farm profile settings
│   │   ├── tasks_screen.dart          # Farm task management
│   │   └── disease_detection/
│   │       ├── disease_detection_screen.dart
│   │       ├── camera_detection_screen.dart
│   │       ├── live_detection_screen.dart
│   │       ├── analysis_result_screen.dart
│   │       └── comprehensive_result_screen.dart
│   ├── services/
│   │   ├── esp32_backend_service.dart
│   │   ├── esp_ap_polling_service.dart
│   │   ├── alert_notification_service.dart
│   │   ├── weather_api_service.dart
│   │   ├── smart_capture_controller.dart
│   │   └── user_mode_service.dart
│   ├── theme/
│   └── widgets/
│       ├── app_card.dart
│       ├── esp32_status_sheet.dart
│       ├── section_header.dart
│       ├── status_tag.dart
│       └── weather_forecast_card.dart
└── pubspec.yaml
```

---

## Configuration

### ESP32 Field Unit Credentials

> ⚠️ **Security:** The firmware ships with placeholder credentials. You **must** change all three values before flashing any deployed device.

Edit `firmware/smartkheti_field_unit/smartkheti_field_unit.ino`:

```cpp
#define AP_SSID  "YourCustomSSID"
#define AP_PASS  "YourStrongPassword!"
#define SMARTKHETI_TOKEN "your-secret-token-here"
```

Update the matching token in `lib/services/esp_ap_polling_service.dart` to match.

### Sensor Read Interval

```cpp
const unsigned long READ_INTERVAL_MS = 4500; // milliseconds
```

### App Hardware Timeout

```dart
// lib/services/esp32_backend_service.dart
static const int _hardwareTimeoutSeconds = 15;
```

---

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to submit issues, propose features, and open pull requests.

---

## License

This project is licensed under the [MIT License](LICENSE).

---

> Built for the **Smart Farming Assistant** challenge — enabling edge-AI precision agriculture for smallholder farmers in India. 🇮🇳
