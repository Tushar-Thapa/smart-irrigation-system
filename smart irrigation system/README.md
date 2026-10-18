# Smart Irrigation - Flutter Android App

A production-grade Flutter Android app for monitoring and controlling an ESP32-based plant-watering system via **Firebase Realtime Database** (Singapore region).

---

## Architecture & Code Structure

The project follows a clean, modular structure under `lib/`:

```
smart_irrigation/
├── android/                             # Android native configuration (minSdk 21, internet permissions)
├── lib/
│   ├── models/
│   │   └── irrigation_data.dart         # Strongly typed model with null-safe parsing & offline detector
│   ├── services/
│   │   └── irrigation_service.dart      # Firebase Realtime Database stream & command writer
│   ├── widgets/
│   │   ├── pump_status_bar.dart         # Prominent top bar showing live pumpOn state with pulse
│   │   ├── reading_card.dart            # Sensor cards (Temp, Humidity, Soil %, Water %) with gauges
│   │   ├── warning_banner.dart          # Low water & sensor fault alerts
│   │   ├── pump_control_section.dart    # Auto / Pump ON / Pump OFF mode buttons with confirmation
│   │   └── connection_status_bar.dart   # Live heartbeat, last update time, and ESP32 offline badge
│   ├── screens/
│   │   └── dashboard_screen.dart        # Main Material 3 dashboard with theme toggle & refresh
│   ├── firebase_options.dart            # Firebase options configured for project smart-irrigation-system-4e066
│   └── main.dart                        # App entry point, Material 3 green theme & dark/light mode
├── pubspec.yaml                         # Dependencies: firebase_core, firebase_database, intl
└── README.md                            # Complete setup, deployment & testing guide
```

---

## 1. Prerequisites & Windows Setup Commands

Run these commands in PowerShell or Windows Command Prompt.

### Step 1: Install Firebase CLI & FlutterFire CLI
```powershell
# 1. Install Firebase CLI globally using npm (Node.js is already installed)
npm install -g firebase-tools

# 2. Login to your Firebase account (opens your browser)
firebase login

# 3. Activate FlutterFire CLI globally via Dart
dart pub global activate flutterfire_cli
```

> **Note:** If `dart` or `flutterfire` isn't found in your PATH after activating, Dart global packages are located at `%LOCALAPPDATA%\Pub\Cache\bin`. Add that directory to your Windows User PATH environment variable or run it directly:
> ```powershell
> & "$env:LOCALAPPDATA\Pub\Cache\bin\flutterfire.bat" configure --project=smart-irrigation-system-4e066
> ```

### Step 2: Configure Firebase for the App
Run this in the project root directory (`c:\Users\ASUS\Desktop\smart irrigation system`):
```powershell
flutterfire configure --project=smart-irrigation-system-4e066
```
- When prompted, select **android** (use arrow keys and spacebar).
- This will automatically generate or update `lib/firebase_options.dart` and download `android/app/google-services.json` directly into your Android app directory.

### Step 3: Fetch Flutter Packages
```powershell
flutter pub get
```

---

## 2. Running on a Real Android Phone over USB

### Step A: Enable Developer Options & USB Debugging on Your Android Phone
1. Open **Settings** on your phone.
2. Go to **About Phone** (or **Software Information** on Samsung devices).
3. Find **Build Number** and tap it **7 times** quickly until you see the message: *"You are now a developer!"*.
4. Go back to the main **Settings** menu, scroll to the bottom, and open **Developer Options**.
5. Scroll down to the **Debugging** section and toggle **USB Debugging** to **ON**.

### Step B: Connect Phone to PC
1. Connect your Android phone to your PC with a USB cable.
2. If your phone asks for USB mode, choose **File Transfer (MTP)** or **MIDI** (not Charge Only).
3. A popup will appear on your phone: **"Allow USB debugging?"**.
4. Check the box **"Always allow from this computer"** and tap **Allow**.

### Step C: Verify & Launch
In your PowerShell terminal:
```powershell
# 1. Check that Flutter detects your phone
flutter devices

# You will see your phone model listed (e.g. "SM-G991B • R5CR... • android-arm64 • Android 14")

# 2. Run the application
flutter run
```

---

## 3. Realtime Database Schema

Node: `/irrigation`
Database URL: `https://smart-irrigation-system-4e066-default-rtdb.asia-southeast1.firebasedatabase.app`

### Payload Structure:
```json
{
  "irrigation": {
    "temperature": 27.5,
    "humidity": 62.0,
    "soilPercent": 48.0,
    "waterPercent": 85.0,
    "waterLow": false,
    "pumpOn": false,
    "sensorOk": true,
    "lastUpdate": 1729200000000,
    "command": "auto"
  }
}
```

---

## 4. Short Testing Checklist

Open the [Firebase Console](https://console.firebase.google.com/) -> Project `smart-irrigation-system-4e066` -> **Realtime Database** -> expand `/irrigation`:

| Test Step | Action in Firebase Console / App | Expected App Behavior |
|---|---|---|
| **1. Pump Status Bar** | Change `"pumpOn": true` | Top bar immediately turns emerald green with **"Pump RUNNING"** and pulsing animation. |
| **2. Pump Idle** | Change `"pumpOn": false` | Top bar turns neutral grey with **"Pump OFF"**. |
| **3. Live Readings** | Edit `temperature`, `humidity`, `soilPercent`, `waterPercent` | Cards update instantaneously without reloading, and progress bars smoothly reflect the levels. |
| **4. Missing Values** | Delete the `temperature` key | Temperature card displays `"--"` safely without crashing or throwing errors. |
| **5. Water Tank Low Alert** | Change `"waterLow": true` | 1) Red warning banner appears: *"Water tank low - refill it. Pump is disabled."*<br>2) "Pump ON" button is disabled with explanation. |
| **6. Sensor Fault Alert** | Change `"sensorOk": false` | 1) Amber warning banner appears: *"Soil sensor problem. Pump is disabled."*<br>2) "Pump ON" button is disabled. |
| **7. Manual Mode Switch** | Tap **"Auto"** or **"Pump OFF"** in the app | App sends command; verify `/irrigation/command` updates to `"auto"` or `"pump_off"` in Firebase Console. |
| **8. Pump ON Confirmation** | Tap **"Pump ON"** (when tank is full and sensor is ok) | Confirmation dialog pops up asking to confirm starting the pump. Tapping **"Start Pump"** writes `"pump_on"` to Firebase. |
| **9. Offline Detection** | Change `"lastUpdate"` to `0` or an epoch timestamp older than 30 seconds | 1) Status badge turns red: **"ESP32 offline"**.<br>2) Reading cards are greyed out / dimmed. |
| **10. Dark & Light Mode** | Tap the moon / sun icon in the top right | Instant smooth transition between Material 3 high-contrast dark mode and crisp light mode. |
