# PondRadar 🌊

> **Hackathon Problem Statement PS 1.1**: Early disease and water-quality alerts for small aquaculture farms in coastal Karnataka (Udupi, Kundapura, Kaup, Mangalore).

PondRadar is a standard, minimal decision-support mobile application for aquaculture farmers and a web dashboard for fisheries officers. It provides:
1. **Pond Water Health Check**: Enter pH, dissolved oxygen, ammonia, and temperature; the pure client-side risk engine returns Low/Medium/High risk, reasons per parameter, an action note, and logs historical trends.
2. **Community Outbreak Radar**: Farmers report pond symptoms in 3 taps (offline-first). Reports are snapped to a ~500m grid for privacy. When reports cluster within 3 km and 48 hours from $\ge 3$ independent farmers, an early-warning outbreak alert is deterministically published and alerts nearby ponds via local notifications.

> **Disclaimer**: *Decision-support aid, not a veterinary diagnosis.*

---

## 🏗️ Architecture & Privacy Design

All business logic runs **entirely client-side** with zero paid Cloud Functions or external servers required.

```
+-----------------------------------------------------------------------------------+
|                                  FARMER APP                                       |
|  - Water Check (pure Dart risk engine)                                            |
|  - 3-Tap Symptom Picker (offline sync)                                            |
|  - Proximity Radar Alerts & Local Notifications                                   |
+-----------------------------------------------------------------------------------+
                                   |           ^
            Writes Reports         |           | Listens to /alerts
                                   v           |
+-----------------------------------------------------------------------------------+
|                                 FIRESTORE                                         |
|  1. /reports_public  --> Snapped to ~500m grid, salted reporter hash (no raw UID) |
|  2. /reports_private --> Exact GPS coordinates & raw UID (Officer read-only)      |
|  3. /alerts          --> Deterministic ID: sha256(gridLat + gridLng + date)        |
|  4. /ponds           --> Farm records & historical parameter readings             |
+-----------------------------------------------------------------------------------+
                                   ^
            Monitors & filters     |
+-----------------------------------------------------------------------------------+
|                             OFFICER WEB DASHBOARD                                 |
|  - Route: /officer (PIN: 8888)                                                    |
|  - Map of reports and 3 km confirmed cluster circles                              |
|  - Filter by 24h/48h/7d and specific symptoms                                     |
|  - 1-click "Load demo data" and "Simulate outbreak"                               |
+-----------------------------------------------------------------------------------+
```

### Privacy-by-Design Safeguards
- **500m Grid Blurring**: The client snaps exact GPS coordinates to a ~500 m grid cell before writing to `reports_public`.
- **Salted Pseudonyms**: User IDs in public reports are hashed with SHA-256 and a local salt (`SymptomReport.hashUserId`), allowing deterministic distinct reporter counts without exposing farmer identity.
- **Role Isolation**: Enforced by `firestore.rules`. Farmers only access public reports and their own ponds; only verified officers can view `reports_private`.

---

## ⚙️ Environment Configuration (`.env`)

All API keys, secrets, and configurable parameters are managed through the `.env` file at the root of the project:

```env
# Google Maps API Key
GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY

# Gemini AI API Key (Optional)
GEMINI_API_KEY=YOUR_GEMINI_API_KEY
ENABLE_GEMINI=false

# Officer Demo Access PIN
OFFICER_PIN=8888

# Firebase Project Credentials
FIREBASE_PROJECT_ID=pondradar-4mt25cs
FIREBASE_WEB_API_KEY=YOUR_FIREBASE_WEB_API_KEY
FIREBASE_ANDROID_API_KEY=YOUR_FIREBASE_ANDROID_API_KEY
FIREBASE_IOS_API_KEY=YOUR_FIREBASE_IOS_API_KEY
```

### Setup Instructions
1. Copy `.env.example` to `.env` (already present and pre-configured for demo):
   ```bash
   cp .env.example .env
   ```
2. Put your real keys into `.env`.
3. If running Android or Web natively with Google Maps, place your Google Maps API key into:
   - **Android**: `android/app/src/main/AndroidManifest.xml` (`meta-data android:name="com.google.android.geo.API_KEY"`)
   - **Web**: `web/index.html` (`<script src="https://maps.googleapis.com/maps/api/js?key=..."></script>`)

## 🚀 Running the Application

### Prerequisites
- Flutter 3.24+ / Dart 3.5+
- Firebase project configured (default: `pondradar-4mt25cs`)

### 1. Run Mobile App (Farmer Experience)
```bash
flutter run
```
- Select **Aquaculture Farmer** on first launch.
- Add a pond or test water readings.
- Toggle between **English** and **ಕನ್ನಡ (Kannada)** on any screen.

### 2. Run Web Dashboard (Officer Experience)
```bash
flutter run -d chrome
```
- Navigate to route `#/officer` or select **Fisheries Officer** on first launch and enter PIN `8888`.
- Click **"Load demo data (40 reports)"** to seed coastal clusters across Kundapura, Udupi Malpe, and Kaup.
- Click **"Simulate outbreak (3 reports)"** to inject 3 reports near a pond and watch the cluster alert and local notification fire live.

### 3. Run Automated Tests
```bash
# Run all unit, widget, and layout scalability tests
flutter test

# Run static analysis
flutter analyze
```

---

## 📊 Datasets & Scientific Sources

All water quality thresholds are consolidated as data in `lib/config/thresholds.dart` with source citations:

| Parameter | Unit | Low Risk (Optimal) | Medium Risk (Caution) | High Risk (Critical) | Source / Reference |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **pH** | - | 7.5 – 8.5 | 7.0 – 7.5 or 8.5 – 9.5 | < 7.0 or > 9.5 | FAO Shrimp Culture Manual, *Water Quality Management* |
| **Dissolved Oxygen** | mg/L | $\ge 4.0$ | 3.0 – 4.0 | < 3.0 | FAO Shrimp Culture Guidelines |
| **Ammonia** | mg/L | $\le 0.1$ | 0.1 – 0.3 | > 0.3 | CIBA / FAO Shrimp Water Guidelines |
| **Temperature** | °C | 26 – 32 | 24 – 26 or 32 – 34 | < 24 or > 34 | Ambient coastal Karnataka brackishwater baseline (TO VERIFY) |

---

## 🧪 Simulated vs. Real Data

| Attribute | Real Farm Data | Simulated Demo Data |
| :--- | :--- | :--- |
| **Marker Flag** | `isSimulated: false` | `isSimulated: true` |
| **Banner** | None | Persistent neutral top strip: *"Simulated demo data"* / *"ಅಣಕು ಡೆಮೊ ಮಾಹಿತಿ"* |
| **Origin** | Logged by farmer through app forms | Seeded via Officer button (`loadDemoData` / `simulateOutbreak`) |
| **Cleanup** | Kept in farmer history | 1-click **"Clear demo data"** button in Officer dashboard |
