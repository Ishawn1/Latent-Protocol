#include <DHT.h>
#include <ModbusMaster.h>
#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>

// Direct on-chip AI model header generated from Kaggle
#include "SmartKhetiAI.h"

// =====================================================
// WIFI ACCESS POINT & API TOKEN
// =====================================================

#define AP_SSID "SmartKheti-Node1"
#define AP_PASS "Field@2025!"
#define SMARTKHETI_TOKEN "smartkheti-field-2025"

WebServer server(80);

// =====================================================
// DHT22 SENSOR
// =====================================================

#define DHT_PIN 4
#define DHT_TYPE DHT22

DHT dht(DHT_PIN, DHT_TYPE);

// =====================================================
// RAIN / WATER SENSOR
// =====================================================

#define WATER_PIN 5
#define WATER_DETECTED_LEVEL HIGH

// =====================================================
// RS485 SOIL SENSOR (MODBUS RTU)
// =====================================================

#define RS485_RX 17
#define RS485_TX 18

#define SOIL_BAUD 4800
#define SOIL_ID 1

HardwareSerial RS485Serial(1);
ModbusMaster soilSensor;

// =====================================================
// SENSOR & AI TELEMETRY STATE
// =====================================================

struct SensorData {
  float airTemp = NAN;
  float airHum = NAN;

  bool waterDetected = false;

  float soilMoisture = 0.0;
  float soilTemperature = 0.0;
  uint16_t soilEC = 0;

  bool soilOK = false;

  // On-chip Edge-AI inference values
  float waterStressProb = 0.0;
  float cropInspectionProb = 0.0;
  bool aiReady = false;
};

SensorData data;

const unsigned long READ_INTERVAL_MS = 4500;
unsigned long lastReadMs = 0;

// =====================================================
// AUTHENTICATION
// =====================================================

bool isAuthorised() {
  if (!server.hasHeader("X-Smartkheti-Token")) {
    return false;
  }
  return server.header("X-Smartkheti-Token") == SMARTKHETI_TOKEN;
}

// =====================================================
// GET /data (REST API)
// =====================================================

void handleGetData() {
  if (!isAuthorised()) {
    server.send(
      401,
      "application/json",
      "{\"error\":\"Unauthorized\"}"
    );
    return;
  }

  StaticJsonDocument<512> doc;

  doc["device"] = "ESP32-S3-N16R8";
  doc["version"] = "v2.0-edge-ai";

  // Environmental readings
  if (!isnan(data.airTemp)) {
    doc["airTemp"] = data.airTemp;
  }
  if (!isnan(data.airHum)) {
    doc["humidity"] = data.airHum;
  }
  doc["rainDetected"] = data.waterDetected;

  // Soil probe readings
  if (data.soilOK) {
    doc["soilMoisture"] = data.soilMoisture;
    doc["soilTemperature"] = data.soilTemperature;
    doc["soilEC"] = data.soilEC;
  } else {
    doc["soilSensorOK"] = false;
  }

  // Edge-AI Predictions
  JsonObject ai = doc.createNestedObject("aiAlerts");
  ai["modelReady"] = data.aiReady;
  ai["waterStressProbability"] = round(data.waterStressProb * 1000.0) / 10.0;
  ai["cropInspectionRisk"] = round(data.cropInspectionProb * 1000.0) / 10.0;
  ai["waterStressAlert"] = (data.waterStressProb >= 0.50f);
  ai["inspectionAlert"] = (data.cropInspectionProb >= 0.50f);

  String output;
  serializeJson(doc, output);

  server.send(
    200,
    "application/json",
    output
  );
}

// =====================================================
// GET / (DASHBOARD)
// =====================================================

void handleRoot() {
  String page;
  page.reserve(1600);

  page += "<!DOCTYPE html><html><head>";
  page += "<title>SmartKheti Field Unit</title>";
  page += "<meta name='viewport' content='width=device-width, initial-scale=1.0'>";
  page += "<style>";
  page += "body{font-family:Arial,sans-serif;padding:20px;background:#f4f6f8;color:#333;}";
  page += ".card{background:#fff;padding:16px;border-radius:10px;box-shadow:0 2px 6px rgba(0,0,0,0.08);margin-bottom:16px;}";
  page += ".badge{padding:4px 8px;border-radius:4px;font-weight:bold;color:#fff;}";
  page += ".badge-ok{background:#28a745;}";
  page += ".badge-warn{background:#dc3545;}";
  page += "</style></head><body>";

  page += "<h2>SmartKheti Edge-AI Unit</h2>";
  page += "<div class='card'>";
  page += "<p><b>System Status:</b> <span class='badge badge-ok'>ONLINE</span></p>";

  if (!isnan(data.airTemp)) {
    page += "<p><b>Air Temperature:</b> " + String(data.airTemp, 1) + " &deg;C</p>";
  }
  if (!isnan(data.airHum)) {
    page += "<p><b>Air Humidity:</b> " + String(data.airHum, 1) + " %</p>";
  }
  page += "<p><b>Rain:</b> " + String(data.waterDetected ? "Detected" : "Not Detected") + "</p>";
  page += "</div>";

  page += "<div class='card'>";
  page += "<h3>Soil Telemetry</h3>";
  if (data.soilOK) {
    page += "<p><b>Soil Moisture:</b> " + String(data.soilMoisture, 1) + " %</p>";
    page += "<p><b>Soil Temperature:</b> " + String(data.soilTemperature, 1) + " &deg;C</p>";
    page += "<p><b>Soil EC:</b> " + String(data.soilEC) + " &micro;S/cm</p>";
  } else {
    page += "<p style='color:#dc3545;'><b>Soil Sensor:</b> ERROR / NO RS485 LINK</p>";
  }
  page += "</div>";

  page += "<div class='card'>";
  page += "<h3>Autonomous Edge-AI Diagnostics</h3>";
  if (data.aiReady) {
    // Water stress assessment
    page += "<p><b>Water Stress Risk:</b> " + String(data.waterStressProb * 100.0, 1) + " % &nbsp;";
    if (data.waterStressProb >= 0.50f) {
      page += "<span class='badge badge-warn'>IRRIGATION NEEDED</span>";
    } else {
      page += "<span class='badge badge-ok'>OPTIMAL</span>";
    }
    page += "</p>";

    // Crop inspection assessment
    page += "<p><b>Crop Inspection Risk:</b> " + String(data.cropInspectionProb * 100.0, 1) + " % &nbsp;";
    if (data.cropInspectionProb >= 0.50f) {
      page += "<span class='badge badge-warn'>INSPECTION REQUIRED</span>";
    } else {
      page += "<span class='badge badge-ok'>HEALTHY</span>";
    }
    page += "</p>";
  } else {
    page += "<p style='color:#6c757d;'>Waiting for active sensor readings...</p>";
  }
  page += "</div>";

  page += "</body></html>";

  server.send(
    200,
    "text/html",
    page
  );
}

// =====================================================
// READ SENSORS & COMPUTE EDGE-AI INFERENCE
// =====================================================

void readAllSensors() {
  // -----------------------------
  // 1. DHT22
  // -----------------------------
  data.airTemp = dht.readTemperature();
  data.airHum = dht.readHumidity();

  // -----------------------------
  // 2. Rain / Water
  // -----------------------------
  data.waterDetected = (digitalRead(WATER_PIN) == WATER_DETECTED_LEVEL);

  // -----------------------------
  // 3. RS485 Modbus Soil Probe
  // -----------------------------
  uint8_t result = soilSensor.readHoldingRegisters(0x0000, 3);
  data.soilOK = (result == soilSensor.ku8MBSuccess);

  if (data.soilOK) {
    data.soilMoisture = soilSensor.getResponseBuffer(0) / 10.0f;
    data.soilTemperature = (int16_t)soilSensor.getResponseBuffer(1) / 10.0f;
    data.soilEC = soilSensor.getResponseBuffer(2);
  }

  // -----------------------------
  // 4. On-Chip Edge AI Inference
  // -----------------------------
  if (data.soilOK && !isnan(data.airTemp) && !isnan(data.airHum)) {
    // Array order strictly matches training order:
    // [soil_moisture_pct, soil_temperature_c, soil_ec_us_cm, air_temperature_c, humidity_pct, rain_detected]
    float rawInputs[6] = {
      data.soilMoisture,
      data.soilTemperature,
      (float)data.soilEC,
      data.airTemp,
      data.airHum,
      data.waterDetected ? 1.0f : 0.0f
    };

    // Sub-millisecond forward pass computed entirely in pure C++
    predictCropStress(rawInputs, data.waterStressProb, data.cropInspectionProb);
    data.aiReady = true;
  } else {
    data.aiReady = false;
  }

  // -----------------------------
  // 5. Serial Diagnostics
  // -----------------------------
  Serial.println();
  Serial.println("==============================================");
  Serial.println("           SMARTKHETI LIVE MONITOR");
  Serial.println("==============================================");

  Serial.println("[ ENVIRONMENT ]");
  if (isnan(data.airTemp) || isnan(data.airHum)) {
    Serial.println("DHT22: SENSOR ERROR");
  } else {
    Serial.print("Air Temperature : ");
    Serial.print(data.airTemp, 1);
    Serial.println(" C");
    Serial.print("Air Humidity    : ");
    Serial.print(data.airHum, 1);
    Serial.println(" %");
  }

  Serial.println();
  Serial.println("[ RAIN / WATER ]");
  Serial.print("Status          : ");
  Serial.println(data.waterDetected ? "RAIN / WATER DETECTED" : "NO RAIN");

  Serial.println();
  Serial.println("[ SOIL RS485 ]");
  if (data.soilOK) {
    Serial.print("Moisture        : ");
    Serial.print(data.soilMoisture, 1);
    Serial.println(" %");
    Serial.print("Temperature     : ");
    Serial.print(data.soilTemperature, 1);
    Serial.println(" C");
    Serial.print("EC              : ");
    Serial.print(data.soilEC);
    Serial.println(" uS/cm");
  } else {
    Serial.println("Soil Sensor     : ERROR / NO RESPONSE");
  }

  Serial.println();
  Serial.println("[ ON-CHIP AI DIAGNOSTICS ]");
  if (data.aiReady) {
    Serial.print("Water Stress Probability : ");
    Serial.print(data.waterStressProb * 100.0f, 1);
    Serial.println(data.waterStressProb >= 0.5f ? " % -> [IRRIGATION NEEDED]" : " % -> [OPTIMAL]");

    Serial.print("Crop Inspection Risk     : ");
    Serial.print(data.cropInspectionProb * 100.0f, 1);
    Serial.println(data.cropInspectionProb >= 0.5f ? " % -> [INSPECTION RECOMMENDED]" : " % -> [HEALTHY]");
  } else {
    Serial.println("AI Status                : WAITING FOR VALID TELEMETRY");
  }

  Serial.println("==============================================");
}

// =====================================================
// SETUP
// =====================================================

void setup() {
  Serial.begin(115200);
  delay(1500);

  Serial.println();
  Serial.println("==============================================");
  Serial.println("       SMARTKHETI FIELD UNIT v2.0-AI");
  Serial.println("==============================================");

  // Initialize Sensors
  dht.begin();
  pinMode(WATER_PIN, INPUT);

  RS485Serial.begin(
    SOIL_BAUD,
    SERIAL_8N1,
    RS485_RX,
    RS485_TX
  );

  soilSensor.begin(
    SOIL_ID,
    RS485Serial
  );

  Serial.println("Sensors initialized.");
  delay(2000); // Give soil probe time to stabilize

  // Configure Wi-Fi Access Point
  WiFi.mode(WIFI_AP);
  bool apStarted = WiFi.softAP(AP_SSID, AP_PASS);

  if (apStarted) {
    Serial.println("Wi-Fi AP started successfully.");
    Serial.print("Network SSID : ");
    Serial.println(AP_SSID);
    Serial.print("Node IP      : ");
    Serial.println(WiFi.softAPIP());
  } else {
    Serial.println("ERROR: Wi-Fi AP failed to start.");
  }

  // Register Web Routes & Headers
  const char* headerKeys[] = {"X-Smartkheti-Token"};
  server.collectHeaders(headerKeys, 1);

  server.on("/", HTTP_GET, handleRoot);
  server.on("/data", HTTP_GET, handleGetData);

  server.begin();
  Serial.println("HTTP Server started. Edge-AI Node Ready.");
}

// =====================================================
// LOOP
// =====================================================

void loop() {
  server.handleClient();

  unsigned long now = millis();
  if (now - lastReadMs >= READ_INTERVAL_MS) {
    lastReadMs = now;
    readAllSensors();
  }
}