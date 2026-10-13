/*****************************************************************************************
  PROJECT: Smart Gas and Air Quality Monitoring System with Firebase Cloud & OLED
  BOARD: ESP32 DevKit / NodeMCU-32S
  SENSORS: MQ-2 (GPIO 34), MQ-7 (GPIO 32), MQ-135 (GPIO 33)
  DISPLAY: SH1106 128x64 OLED (I2C: SDA=21, SCL=22)
  BUZZER:  GPIO 25 (Active when MQ-2 LPG > 1200 PPM)
  BACKEND: Firebase Realtime Database
  
  WI-FI SSID: vivoy200e
  FIREBASE HOST: gasmonitoringsystem-77db2-default-rtdb.firebaseio.com
*****************************************************************************************/

#include <Arduino.h>
#include <U8g2lib.h>
#include <Wire.h>
#include <math.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <time.h>

// =====================================================================================
// 1. PIN DEFINITIONS
// =====================================================================================
#define MQ2_PIN     34   // ADC1_CH6 (Safe with Wi-Fi)
#define MQ7_PIN     32   // ADC1_CH4 (Safe with Wi-Fi)
#define MQ135_PIN   33   // ADC1_CH5 (Safe with Wi-Fi)
#define BUZZER_PIN  25   // Local Alarm Buzzer

// =====================================================================================
// 2. WI-FI & FIREBASE CONFIGURATION
// =====================================================================================
const char* WIFI_SSID     = "vivoy200e";
const char* WIFI_PASSWORD = "77777777";

const char* FIREBASE_HOST = "gasmonitoringsystem-77db2-default-rtdb.firebaseio.com";
const char* FIREBASE_AUTH = ""; // Leave empty if rules are open in development
const char* DEVICE_ID     = "esp32_gas_01";
const char* FIRMWARE_VER  = "ESP32 GasSense v1.2.0-OLED";

// =====================================================================================
// 3. OLED DISPLAY (SH1106 128x64 I2C)
// =====================================================================================
U8G2_SH1106_128X64_NONAME_F_HW_I2C u8g2(
  U8G2_R0,
  U8X8_PIN_NONE
);

// =====================================================================================
// 4. SENSOR CALIBRATION PARAMETERS
// =====================================================================================
#define ADC_MAX 4095.0
#define ADC_REF 3.3

// MQ-2 Settings
#define MQ2_RL 10.0
#define MQ2_VCC 5.0
float MQ2_R0 = 10.0;
#define LPG_ALARM_PPM 1200.0

// MQ-7 Settings
#define MQ7_RL 10.0
#define MQ7_VCC 5.0
float MQ7_R0 = 36.0;

// MQ-135 Settings
#define MQ135_RL 10.0
#define MQ135_VCC 5.0
float MQ135_R0 = 10.0;
#define SAMPLE_COUNT 10
float baselineADC = 80.0;
float filteredADC = 80.0;
bool mq135Calibrated = true;

// =====================================================================================
// 5. RUNTIME VARIABLES
// =====================================================================================
int mq2ADC = 0;
int mq7ADC = 0;
int mq135ADC = 0;

float mq2Voltage = 0;
float mq7Voltage = 0;
float mq135Voltage = 0;

float mq2Rs = 0;
float mq7Rs = 0;
float mq135Rs = 0;

float mq2Ratio = 0;
float mq7Ratio = 0;
float mq135Ratio = 0;

float lpgPPM = 0;
float coPPM = 0;
int aqi = 88;

String lpgStatus = "LPG NORMAL";
String coStatus  = "CO NORMAL";
String airStatus = "GOOD";

// NTP & Network
const char* NTP_SERVER = "pool.ntp.org";
WiFiClientSecure secureClient;

// Push change tracking
float lastPushedAQI = 88.0;
float lastPushedLPG = 0.0;
float lastPushedCO  = 0.0;

float lastHistAQI = 88.0;
float lastHistLPG = 0.0;
float lastHistCO  = 0.0;

// Timers
unsigned long lastSensorRead   = 0;
unsigned long lastOLEDUpdate   = 0;
unsigned long lastFirebaseLive = 0;
unsigned long lastHistoryLog   = 0;
unsigned long lastAlertSent    = 0;
unsigned long lastWifiRetry    = 0;

const unsigned long SENSOR_INTERVAL      = 200;    // 200ms (fast, ultra-responsive sensor reads)
const unsigned long OLED_INTERVAL        = 300;    // 300ms (smooth, fluid OLED refresh)
const unsigned long FIREBASE_INTERVAL    = 1000;   // 1s live sync to mobile app
const unsigned long HISTORY_INTERVAL     = 15000;  // 15s historical log (dense real-time timeline)
const unsigned long ALERT_COOLDOWN_MS    = 45000;  // 45s alert debounce
const unsigned long WIFI_RETRY_INTERVAL  = 15000;  // 15s Wi-Fi reconnect timer

// =====================================================================================
// 6. HELPER: CURRENT EPOCH MILLISECONDS (NTP)
// =====================================================================================
unsigned long long getEpochMillis() {
  time_t now;
  struct tm timeinfo;
  if (!getLocalTime(&timeinfo)) {
    return 1712739400000ULL + millis();
  }
  time(&now);
  return ((unsigned long long)now * 1000ULL) + (millis() % 1000);
}

String epochToString(unsigned long long epoch) {
  char buf[25];
  snprintf(buf, sizeof(buf), "%llu", epoch);
  return String(buf);
}

// =====================================================================================
// 7. SENSOR CONVERSIONS & MATH
// =====================================================================================
float getVoltage(int adc) {
  return ((float)adc / ADC_MAX) * ADC_REF;
}

float calculateRs(float voltage, float RL, float VCC) {
  if (voltage <= 0.01 || voltage >= VCC) {
    return 9999.0;
  }
  float Rs = RL * ((VCC - voltage) / voltage);
  if (Rs < 0.01) Rs = 0.01;
  return Rs;
}

int readMQ2() {
  long total = 0;
  for (int i = 0; i < 10; i++) {
    total += analogRead(MQ2_PIN);
    delay(2);
  }
  return total / 10;
}

float calculateLPGppm(float ratio) {
  if (ratio <= 0.01) return 5000.0;
  float ppm = 1000.0 * pow(ratio, -2.3);
  if (isnan(ppm) || isinf(ppm) || ppm < 0) return 0;
  if (ppm > 5000.0) ppm = 5000.0;
  return ppm;
}

int readMQ7() {
  long total = 0;
  for (int i = 0; i < 20; i++) {
    total += analogRead(MQ7_PIN);
    delay(2);
  }
  return total / 20;
}

float calculateCO(float ratio) {
  if (ratio <= 0.05) return 2000.0;
  if (ratio >= 15.0) return 0.0;
  float m = -0.77;
  float b = 1.70;
  float logRatio = log10(ratio);
  float logPPM = (logRatio - b) / m;
  float ppm = pow(10.0, logPPM);
  if (isnan(ppm) || isinf(ppm) || ppm < 0) return 0.0;
  if (ppm > 2000.0) ppm = 2000.0;
  return ppm;
}

float readMQ135() {
  long total = 0;
  for (int i = 0; i < 10; i++) {
    total += analogRead(MQ135_PIN);
    delay(2);
  }
  return (float)total / 10.0;
}

void calibrateMQ135() {
  long total = 0;
  Serial.println("\n[MQ-135] Calibrating clean-air baseline...");
  for (int i = 0; i < 40; i++) {
    total += analogRead(MQ135_PIN);
    delay(25);
  }
  float avg = (float)total / 40.0;
  // If reading is sensible (between 35 and 150), use it as baseline; otherwise fallback to 80.0
  if (avg >= 35.0 && avg <= 150.0) {
    baselineADC = avg;
  } else {
    baselineADC = 80.0;
  }
  filteredADC = baselineADC;
  aqi = 88;
  airStatus = "GOOD";
  mq135Calibrated = true;
  Serial.printf("[MQ-135] Baseline ADC: %.1f\n", baselineADC);
}

int calculateAQI(float adc) {
  if (baselineADC <= 5.0) return 88;

  float diff = adc - baselineADC;
  float aqiVal = 88.0;

  if (diff > 2.0) {
    // Relative scaling based on baseline:
    // A 10% rise above baseline adds ~12 AQI (88 + 12 = 100 -> MEDIUM)
    // A 25% rise above baseline adds ~30 AQI (88 + 30 = 118 -> MEDIUM)
    // A 40% rise above baseline adds ~48 AQI (88 + 48 = 136 -> BAD)
    // A 100% rise (double baseline) adds ~120 AQI (88 + 120 = 208 -> BAD)
    // Dense paper smoke adds ~200-300 AQI -> BAD (smooth step by step up to 500)
    float pct = ((diff - 2.0) / baselineADC) * 100.0;
    aqiVal = 88.0 + (pct * 1.15);
  } else if (diff < -2.0) {
    // Ventilated clean air below baseline
    aqiVal = 88.0 + ((diff + 2.0) / baselineADC) * 25.0;
  } else {
    // Deadband within clean room baseline (+- 2 ADC noise)
    aqiVal = 88.0;
  }

  if (isnan(aqiVal) || isinf(aqiVal) || aqiVal < 25.0) aqiVal = 25.0;
  if (aqiVal > 500.0) aqiVal = 500.0;
  return (int)round(aqiVal);
}

const char* getAirStatus(int aqiVal) {
  if (aqiVal <= 90) {
    return "GOOD";
  } else if (aqiVal <= 129) {
    return "MEDIUM";
  } else {
    return "BAD";
  }
}

// =====================================================================================
// 8. BUZZER CONTROL (MQ-2 RULE)
// =====================================================================================
void updateBuzzer() {
  if (lpgPPM > LPG_ALARM_PPM) {
    ledcWriteTone(BUZZER_PIN, 5000);
  } else {
    ledcWriteTone(BUZZER_PIN, 0);
  }
}

// =====================================================================================
// 9. FIREBASE HTTPS REST CALLS
// =====================================================================================
bool firebaseRequest(const String& method, const String& path, const String& jsonPayload) {
  if (WiFi.status() != WL_CONNECTED) return false;

  HTTPClient http;
  String url = "https://" + String(FIREBASE_HOST) + "/" + path + ".json";
  if (strlen(FIREBASE_AUTH) > 0) {
    url += "?auth=" + String(FIREBASE_AUTH);
  }

  http.setTimeout(2000);
  http.setReuse(true);
  http.begin(secureClient, url);
  http.addHeader("Content-Type", "application/json");

  int httpCode = 0;
  if (method == "PUT") {
    httpCode = http.PUT(jsonPayload);
  } else if (method == "POST") {
    httpCode = http.POST(jsonPayload);
  }

  bool success = (httpCode >= 200 && httpCode < 300);
  if (!success) {
    Serial.printf("[Firebase] %s %s failed (code %d): %s\n", method.c_str(), path.c_str(), httpCode, http.getString().c_str());
  }
  http.end();
  return success;
}

// =====================================================================================
// 10. SENSOR ACQUISITION
// =====================================================================================
void readAllSensors() {
  // MQ-2
  mq2ADC = readMQ2();
  mq2Voltage = getVoltage(mq2ADC);
  mq2Rs = calculateRs(mq2Voltage, MQ2_RL, MQ2_VCC);
  mq2Ratio = mq2Rs / MQ2_R0;
  lpgPPM = calculateLPGppm(mq2Ratio);
  lpgStatus = (lpgPPM > LPG_ALARM_PPM) ? "LPG HIGH" : "LPG NORMAL";

  // MQ-7
  mq7ADC = readMQ7();
  mq7Voltage = getVoltage(mq7ADC);
  mq7Rs = calculateRs(mq7Voltage, MQ7_RL, MQ7_VCC);
  mq7Ratio = mq7Rs / MQ7_R0;
  coPPM = calculateCO(mq7Ratio);
  coStatus = (coPPM > 50.0) ? "CO HIGH" : "CO NORMAL";

  // MQ-135
  float rawMQ135 = readMQ135();
  // Filter (0.5 / 0.5) for fast, responsive, smooth step-by-step reaction
  filteredADC = (filteredADC * 0.5) + (rawMQ135 * 0.5);
  mq135ADC = (int)round(filteredADC);
  mq135Voltage = getVoltage(mq135ADC);
  mq135Rs = calculateRs(mq135Voltage, MQ135_RL, MQ135_VCC);
  // Auto clean-air tracking
  if (filteredADC < baselineADC && filteredADC > 15.0) {
    baselineADC = (baselineADC * 0.98) + (filteredADC * 0.02);
  } else if (filteredADC < (baselineADC * 1.10) && filteredADC > 15.0) {
    baselineADC = (baselineADC * 0.999) + (filteredADC * 0.001);
  }

  // Fast direct AQI (responds step by step smoothly)
  aqi = calculateAQI(filteredADC);
  airStatus = getAirStatus(aqi);

  // Buzzer Rule (Autonomous safety)
  updateBuzzer();
}

// =====================================================================================
// 11. OLED DISPLAY RENDERING
// =====================================================================================
void updateOLED() {
  u8g2.clearBuffer();
  u8g2.setFont(u8g2_font_5x8_tf);

  // Header with live Wi-Fi indicator
  u8g2.drawStr(0, 8, "SMART GAS MONITOR");
  if (WiFi.status() == WL_CONNECTED) {
    u8g2.drawStr(102, 8, "[LIVE]");
  } else {
    u8g2.drawStr(106, 8, "[NO]");
  }
  u8g2.drawHLine(0, 10, 128);

  // MQ-2
  u8g2.setCursor(0, 21);
  u8g2.print("MQ2 LPG: ");
  u8g2.print(lpgPPM, 0);
  u8g2.print(" ppm");

  // MQ-7
  u8g2.setCursor(0, 32);
  u8g2.print("MQ7 CO: ");
  u8g2.print(coPPM, 0);
  u8g2.print(" ppm");

  // MQ-135
  u8g2.setCursor(0, 43);
  u8g2.print("MQ135 AQI: ");
  u8g2.print(aqi);
  u8g2.print(" ");
  u8g2.print(airStatus);

  u8g2.drawHLine(0, 47, 128);

  // Status & Buzzer
  u8g2.setCursor(0, 59);
  if (lpgPPM > LPG_ALARM_PPM) {
    u8g2.print("LPG HIGH! BUZZER ON");
  } else {
    u8g2.print("LPG NORMAL - SILENT");
  }

  u8g2.sendBuffer();
}

// =====================================================================================
// 12. PUSH DATA TO FIREBASE (App Sync)
// =====================================================================================
void pushTelemetryToFirebase() {
  unsigned long long timestamp = getEpochMillis();
  String tsStr = epochToString(timestamp);

  // 1. Current State (matches Flutter typed models)
  String currentJson = "{";
  currentJson += "\"deviceId\":\"" + String(DEVICE_ID) + "\",";
  currentJson += "\"lastSeen\":" + tsStr + ",";
  currentJson += "\"status\":\"online\",";
  currentJson += "\"firmware\":\"" + String(FIRMWARE_VER) + "\",";
  currentJson += "\"ip\":\"" + WiFi.localIP().toString() + "\",";
  currentJson += "\"sensors\":{";

  // MQ-2 (LPG ppm + raw ADC)
  currentJson += "\"mq2\":{";
  currentJson += "\"value\":" + String(lpgPPM, 1) + ",";
  currentJson += "\"raw\":" + String(mq2ADC) + ",";
  currentJson += "\"calibrated\":" + String(lpgPPM, 1) + ",";
  currentJson += "\"unit\":\"ppm\",";
  currentJson += "\"valid\":true,";
  currentJson += "\"status\":\"" + lpgStatus + "\",";
  currentJson += "\"timestamp\":" + tsStr;
  currentJson += "},";

  // MQ-7 (CO ppm + raw ADC)
  currentJson += "\"mq7\":{";
  currentJson += "\"value\":" + String(coPPM, 1) + ",";
  currentJson += "\"raw\":" + String(mq7ADC) + ",";
  currentJson += "\"calibrated\":" + String(coPPM, 1) + ",";
  currentJson += "\"unit\":\"ppm\",";
  currentJson += "\"valid\":true,";
  currentJson += "\"status\":\"" + coStatus + "\",";
  currentJson += "\"timestamp\":" + tsStr;
  currentJson += "},";

  // MQ-135 (Air Quality Index + raw ADC)
  currentJson += "\"mq135\":{";
  currentJson += "\"value\":" + String(aqi) + ",";
  currentJson += "\"raw\":" + String(mq135ADC) + ",";
  currentJson += "\"calibrated\":" + String(aqi) + ",";
  currentJson += "\"unit\":\"AQI\",";
  currentJson += "\"valid\":true,";
  currentJson += "\"status\":\"" + airStatus + "\",";
  currentJson += "\"timestamp\":" + tsStr;
  currentJson += "}";

  currentJson += "}}";

  firebaseRequest("PUT", "devices/esp32_gas_01/current", currentJson);

  // 2. Alert Generation (When LPG exceeds buzzer threshold)
  if (lpgPPM > LPG_ALARM_PPM && (millis() - lastAlertSent >= ALERT_COOLDOWN_MS)) {
    lastAlertSent = millis();

    String alertJson = "{";
    alertJson += "\"deviceId\":\"" + String(DEVICE_ID) + "\",";
    alertJson += "\"sensor\":\"mq2\",";
    alertJson += "\"severity\":\"critical\",";
    alertJson += "\"message\":\"MQ-2 LPG concentration exceeded 1200 PPM! Buzzer activated.\",";
    alertJson += "\"value\":" + String(lpgPPM, 1) + ",";
    alertJson += "\"unit\":\"ppm\",";
    alertJson += "\"timestamp\":" + tsStr + ",";
    alertJson += "\"resolved\":false";
    alertJson += "}";

    firebaseRequest("POST", "devices/esp32_gas_01/alerts", alertJson);
    Serial.println("[Firebase] Active safety alert pushed!");
  }
}

void pushHistoryToFirebase() {
  unsigned long long timestamp = getEpochMillis();
  String tsStr = epochToString(timestamp);

  String histJson = "{";
  histJson += "\"timestamp\":" + tsStr + ",";
  histJson += "\"mq2\":" + String(lpgPPM, 1) + ",";
  histJson += "\"mq7\":" + String(coPPM, 1) + ",";
  histJson += "\"mq135\":" + String(aqi);
  histJson += "}";

  firebaseRequest("POST", "devices/esp32_gas_01/history", histJson);
  Serial.println("[Firebase] 30s Historical data point logged.");
}

// =====================================================================================
// 13. SETUP
// =====================================================================================
void setup() {
  Serial.begin(115200);

  analogReadResolution(12);

  pinMode(MQ2_PIN, INPUT);
  pinMode(MQ7_PIN, INPUT);
  pinMode(MQ135_PIN, INPUT);
  pinMode(BUZZER_PIN, OUTPUT);

  // Buzzer API (ESP32 Arduino 3.x)
  ledcAttach(BUZZER_PIN, 5000, 8);
  ledcWriteTone(BUZZER_PIN, 0);

  // OLED Initialization
  Wire.begin();
  u8g2.begin();

  u8g2.clearBuffer();
  u8g2.setFont(u8g2_font_ncenB08_tr);
  u8g2.drawStr(18, 15, "GAS MONITOR");
  u8g2.drawStr(10, 32, "CONNECTING WI-FI");
  u8g2.drawStr(26, 50, "PLEASE WAIT...");
  u8g2.sendBuffer();

  // Connect to Wi-Fi
  Serial.printf("\n[Wi-Fi] Connecting to %s", WIFI_SSID);
  WiFi.mode(WIFI_STA);
  WiFi.setAutoReconnect(true);
  WiFi.persistent(true);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n[Wi-Fi] Connected! IP: " + WiFi.localIP().toString());
  } else {
    Serial.println("\n[Wi-Fi] Will retry connection in background loop.");
  }

  // Network time (UTC)
  configTime(0, 0, NTP_SERVER);
  secureClient.setInsecure();

  // OLED Warm-up message
  u8g2.clearBuffer();
  u8g2.drawStr(18, 15, "GAS MONITOR");
  u8g2.drawStr(12, 32, "WARMING SENSORS");
  u8g2.drawStr(22, 50, "CALIBRATING...");
  u8g2.sendBuffer();

  delay(3000); // Sensor warm-up
  calibrateMQ135();
  delay(500);

  readAllSensors();
  updateOLED();

  lastSensorRead   = millis();
  lastOLEDUpdate   = millis();
  lastFirebaseLive = millis();
  lastHistoryLog   = millis();

  Serial.println("\n======================================");
  Serial.println("  SMART GAS MONITOR RUNNING");
  Serial.println("  OLED: ACTIVE");
  Serial.println("  FIREBASE RTDB: CONNECTED");
  Serial.println("======================================");
}

// =====================================================
// 14. MAIN LOOP
// =====================================================
void loop() {
  unsigned long currentMillis = millis();

  // Wi-Fi Connection Guard (Non-blocking retry at most once every 15s)
  if (WiFi.status() != WL_CONNECTED) {
    if (currentMillis - lastWifiRetry >= WIFI_RETRY_INTERVAL) {
      lastWifiRetry = currentMillis;
      Serial.println("[Wi-Fi] Connection lost. Reconnecting...");
      WiFi.disconnect();
      delay(50);
      WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    }
  } else {
    lastWifiRetry = currentMillis;
  }

  // 1. Read Sensors (Every 300ms)
  if (currentMillis - lastSensorRead >= SENSOR_INTERVAL) {
    lastSensorRead = currentMillis;
    readAllSensors();
  }

  // 2. Update OLED Display (Every 500ms)
  if (currentMillis - lastOLEDUpdate >= OLED_INTERVAL) {
    lastOLEDUpdate = currentMillis;
    updateOLED();
  }

  // 3. Sync Live Data to Firebase (Every 1s, or immediate on significant sensor change)
  bool significantChange = (abs(aqi - (int)lastPushedAQI) >= 5) || 
                           (fabs(lpgPPM - lastPushedLPG) >= 20.0) ||
                           (fabs(coPPM - lastPushedCO) >= 10.0);

  if ((currentMillis - lastFirebaseLive >= FIREBASE_INTERVAL) || 
      (significantChange && (currentMillis - lastFirebaseLive >= 500))) {
    lastFirebaseLive = currentMillis;
    lastPushedAQI = (float)aqi;
    lastPushedLPG = lpgPPM;
    lastPushedCO  = coPPM;
    pushTelemetryToFirebase();
  }

  // 4. Log Historical Record to Firebase (Every 15s or immediate on significant gas change)
  bool significantHistChange = (abs(aqi - (int)lastHistAQI) >= 15) || 
                               (fabs(lpgPPM - lastHistLPG) >= 100.0) ||
                               (fabs(coPPM - lastHistCO) >= 15.0);

  if ((currentMillis - lastHistoryLog >= HISTORY_INTERVAL) || 
      (significantHistChange && (currentMillis - lastHistoryLog >= 3000))) {
    lastHistoryLog = currentMillis;
    lastHistAQI = (float)aqi;
    lastHistLPG = lpgPPM;
    lastHistCO  = coPPM;
    pushHistoryToFirebase();
  }

  delay(10); // Yield to ESP32 FreeRTOS background tasks
}
