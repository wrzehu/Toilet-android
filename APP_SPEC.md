# 🚽 Toilet Timer — Android App Specification

> **Platform:** Android (Native — Kotlin + Jetpack Compose)
> **Repo:** `Toilet-android`
> **Target SDK:** API 26+ (Android 8.0 Oreo and above)
> **Language:** Kotlin
> **UI Framework:** Jetpack Compose
> **Backend:** Firebase (Firestore + Authentication)
> **Ads:** Google AdMob (Banner + Interstitial)
> **Localization:** Android `strings.xml` resource system (multi-language ready)

---

## 📖 App Overview

**Toilet Timer** is a fun, social countdown app designed to hurry up people sitting too long on the toilet.

The app operates in two roles:
- **SITTER** — the person on the toilet who controls the timer
- **WAITER** — the person(s) waiting outside who receives the alarm

Devices are paired via QR code scanning and communicate in real-time through Firebase Firestore.

---

## 🏗️ Tech Stack

| Layer | Technology |
|---|---|
| Language | Kotlin |
| UI | Jetpack Compose |
| Architecture | MVVM + Clean Architecture |
| Backend / Realtime DB | Firebase Firestore |
| Auth | Firebase Anonymous Auth |
| Storage | Firebase Storage (for user assets) |
| Notifications | Firebase Cloud Messaging (FCM) |
| Ads | Google AdMob |
| QR Generation | `zxing-android-embedded` or `core` |
| QR Scanning | `ML Kit Barcode Scanning` |
| Animations | Jetpack Compose Animations + Lottie |
| Localization | Android `res/values/strings.xml` |
| DI | Hilt |
| Navigation | Compose Navigation |

---

## 📁 Project Structure

```
app/
├── src/main/
│   ├── java/com/toilettimer/android/
│   │   ├── MainActivity.kt
│   │   ├── di/                        # Hilt modules
│   │   ├── data/
│   │   │   ├── remote/                # Firebase Firestore repositories
│   │   │   └── model/                 # Data classes (Session, Device, Timer)
│   │   ├── domain/
│   │   │   ├── usecase/               # Use cases
│   │   │   └── repository/            # Repository interfaces
│   │   ├── ui/
│   │   │   ├── theme/                 # MaterialTheme, Colors, Typography
│   │   │   ├── screen/
│   │   │   │   ├── splash/            # SplashScreen
│   │   │   │   ├── roleselect/        # SITTER / WAITER selection screen
│   │   │   │   ├── sitter/            # SITTER main screen (timer control)
│   │   │   │   ├── waiter/            # WAITER waiting screen
│   │   │   │   ├── pair/              # QR pairing screen
│   │   │   │   └── settings/          # Settings screen
│   │   │   ├── component/             # Shared Composables
│   │   │   └── animation/             # Custom animation composables
│   │   └── util/                      # Extensions, helpers
│   ├── res/
│   │   ├── values/strings.xml         # EN strings (default)
│   │   ├── values-pl/strings.xml      # PL strings
│   │   ├── values-de/strings.xml      # DE strings
│   │   ├── raw/                       # Sound files (alarm sound — to be provided)
│   │   └── drawable/                  # App graphics (to be provided)
│   └── AndroidManifest.xml
```

---

## 🖥️ Screens

### 1. Splash Screen

- Show app logo briefly (1.5s)
- Check if user has a saved role (SITTER/WAITER) and session
- Navigate to **Role Selection** or directly to the appropriate main screen

---

### 2. Role Selection Screen (`RoleSelectScreen`)

**Layout:**
- Screen divided **50/50 horizontally** into two tappable tiles
- **Left tile — SITTER:**
  - Background: provided graphic (placeholder: `ic_sitter.png`)
  - Label: `strings/role_sitter` (e.g. "SITTER")
  - Subtitle: `strings/role_sitter_desc` (e.g. "I'm on the throne")
- **Right tile — WAITER:**
  - Background: provided graphic (placeholder: `ic_waiter.png`)
  - Label: `strings/role_waiter` (e.g. "WAITER")
  - Subtitle: `strings/role_waiter_desc` (e.g. "I'm waiting outside")
- Each tile has a subtle ripple/scale press animation

**Behavior:**
- On SITTER tap → navigate to **SITTER Main Screen**
- On WAITER tap → navigate to **WAITER Main Screen**
- Role is saved to local SharedPreferences / DataStore

---

### 3. SITTER Main Screen (`SitterScreen`)

**Layout:**
- Top bar:
  - App title (centered)
  - ⚙️ Settings button (top-right corner) → navigates to **Settings Screen**
- Center: **Main Animation** (see Animation section)
- Timer preset selector (4 large buttons):
  - `5 min` / `10 min` / `15 min` / `30 min`
  - Strings: `timer_5min`, `timer_10min`, `timer_15min`, `timer_30min`
- **START** button
  - Strings: `btn_start`
- Bottom: **AdMob Banner Ad** (always visible when timer is NOT running)

**Behavior:**
- SITTER selects a preset duration
- SITTER taps START → timer starts; a Firestore document is updated with `{ status: "running", duration: X, startedAt: timestamp }` for all paired WAITERs
- When timer is running:
  - Countdown is shown on screen
  - AdMob banner is **hidden**
  - A **STOP** button appears (`btn_stop`)
- When countdown reaches 0:
  - Play alarm sound (`raw/alarm_sound.mp3` — to be provided by client)
  - Show completion animation / text
  - Firestore document updated to `{ status: "finished" }`

**Paired WAITERs list:**
- Below timer presets, show a list of connected WAITER devices (name/ID)
- Each entry shows connection status (online/offline)

---

### 4. WAITER Main Screen (`WaiterScreen`)

**Layout:**
- Top bar:
  - App title (centered)
  - ⚙️ Settings button (top-right corner)
- Center: **Waiting state animation** (same animation as SITTER but read-only view)
- Large countdown display (synced from Firebase in real-time)
- Status label: `strings/waiter_waiting`, `strings/waiter_countdown`, `strings/waiter_done`
- Bottom: **AdMob Banner Ad** (always visible)

**Behavior:**
- WAITER listens to Firestore in real-time for timer updates from their paired SITTER
- When `status == "running"`: show live countdown synced to `startedAt + duration`
- When `status == "finished"`:
  - Play alarm sound locally (`raw/alarm_sound.mp3`)
  - Show **Full-Screen Interstitial Ad** (AdMob Interstitial)
  - After ad dismissed: show completion screen with message (`strings/waiter_time_up`)
- When SITTER presses STOP mid-countdown:
  - Show **Full-Screen Interstitial Ad** (AdMob Interstitial) immediately
  - After ad dismissed: return to idle waiting state

> [!IMPORTANT]
> The full-screen ad must appear on WAITER's device both when the timer finishes AND when the SITTER interrupts the countdown.

---

### 5. QR Pairing Screen (`PairScreen`)

**Two modes depending on role:**

#### SITTER — Generate QR
- Generate a QR code containing: `{ sitterId: <uid>, sessionToken: <token> }`
- Display QR code centered on screen
- Instruction text: `strings/pair_show_qr`
- Below QR: list of already paired WAITERs (can be removed from here or Settings)

#### WAITER — Scan QR
- Open camera to scan QR code
- On successful scan: call Firebase Cloud Function / Firestore to register WAITER under that SITTER session
- Success → navigate to WAITER Main Screen
- Instruction text: `strings/pair_scan_qr`

**Navigation:** Accessible from Settings Screen for both roles

---

### 6. Settings Screen (`SettingsScreen`)

**Layout:**
- Top bar with back button and title (`strings/settings_title`)
- ⚙️ icon in top-right (decorative or sub-settings)

**SITTER Settings:**
- Section: `strings/settings_paired_waiters`
  - List of paired WAITER devices (display name or device ID)
  - Each item: remove button (❌) → removes from Firestore pairing
  - Button: `strings/settings_add_waiter` → opens QR Pairing Screen (generate mode) to let a new WAITER scan
- Section: `strings/settings_animation`
  - Toggle between two animation styles:
    - Option A: `strings/anim_sand` — Sandglass man (sand falling through toilet)
    - Option B: `strings/anim_skeleton` — Fade to skeleton
- Section: `strings/settings_language`
  - Dropdown / list to switch app language (override system language)
  - Currently supported: English, Polish, German
  - Strings: `settings_language`, `lang_en`, `lang_pl`, `lang_de`

**WAITER Settings:**
- Section: `strings/settings_my_sitters`
  - List of SITTER devices this WAITER is connected to
  - Each item: remove / disconnect button
  - Button: `strings/settings_share_qr` → opens QR Pairing Screen (scan mode) to connect to a new SITTER

> [!NOTE]
> A SITTER can have **multiple WAITERs** paired. A WAITER can be paired to **multiple SITTERs**.

---

## 🎬 Animations

Two animation styles — user selects preferred in Settings.

### Option A: "Sandglass Man" 🏖️
- Displayed on the main screen center area
- Background: illustration of a man sitting on a toilet
- The toilet bowl has a transparent section (Compose `Canvas` or Lottie)
- Sand particles fall continuously from top to bottom within the bowl
- Sand uses a particle system (Compose Canvas `drawCircle` with random positions + falling `AnimationSpec`)
- Animation loops indefinitely while idle; when timer runs, sand falls faster

### Option B: "Skeleton Fade" 💀
- Two identical illustrations: one of a normal man on toilet, one of a skeleton on toilet
- Composable cross-fades between them using `AnimatedContent` with `fadeIn/fadeOut`
- Fade period: configurable (default 4 seconds per cycle, looping)
- During countdown: fade speed increases as timer approaches 0

> [!NOTE]
> Both illustration assets will be provided by the client. Use clearly named placeholders: `drawable/anim_man_normal.png` and `drawable/anim_man_skeleton.png`.

---

## 🔔 Sound

- Alarm sound file: `res/raw/alarm_sound.mp3` — **to be provided by client**
- Played using Android `MediaPlayer` or `SoundPool`
- Played on **both** SITTER and WAITER devices when timer reaches 0
- Sound respects device volume / ringer mode

---

## 📢 Advertising (AdMob)

| Placement | Type | Trigger |
|---|---|---|
| SITTER timer setup screen (bottom) | Banner | Always visible when timer not running |
| WAITER waiting screen (bottom) | Banner | Always visible |
| WAITER — timer finished | Interstitial (full-screen) | When `status == "finished"` |
| WAITER — timer interrupted by SITTER | Interstitial (full-screen) | When `status == "stopped"` |

- AdMob App ID and Ad Unit IDs: stored in `res/values/strings.xml` under `admob_app_id`, `admob_banner_id`, `admob_interstitial_id`
- Use **test ad IDs** during development

---

## 🌐 Localization

All user-visible text must use string resources. No hardcoded strings anywhere.

**Required string keys (base set):**

```xml
<!-- Roles -->
<string name="role_sitter">SITTER</string>
<string name="role_sitter_desc">I\'m on the throne</string>
<string name="role_waiter">WAITER</string>
<string name="role_waiter_desc">I\'m waiting outside</string>

<!-- Timer -->
<string name="timer_5min">5 min</string>
<string name="timer_10min">10 min</string>
<string name="timer_15min">15 min</string>
<string name="timer_30min">30 min</string>
<string name="btn_start">START</string>
<string name="btn_stop">STOP</string>

<!-- Waiter states -->
<string name="waiter_waiting">Waiting for the signal…</string>
<string name="waiter_countdown">Time remaining: %1$s</string>
<string name="waiter_time_up">TIME\'S UP! 🚽</string>
<string name="waiter_stopped">Timer was stopped.</string>

<!-- Pairing -->
<string name="pair_show_qr">Show this QR code to your WAITER</string>
<string name="pair_scan_qr">Scan the SITTER\'s QR code</string>
<string name="pair_success">Successfully paired!</string>
<string name="pair_error">Pairing failed. Please try again.</string>

<!-- Settings -->
<string name="settings_title">Settings</string>
<string name="settings_paired_waiters">Paired WAITERs</string>
<string name="settings_add_waiter">Add WAITER (show QR)</string>
<string name="settings_my_sitters">My SITTERs</string>
<string name="settings_share_qr">Connect to SITTER (scan QR)</string>
<string name="settings_animation">Animation Style</string>
<string name="settings_language">Language</string>
<string name="anim_sand">Sandglass Man</string>
<string name="anim_skeleton">Fade to Skeleton</string>
<string name="lang_en">English</string>
<string name="lang_pl">Polish</string>
<string name="lang_de">German</string>
```

---

## 🔒 Firebase Data Model

### Collection: `sessions`

```
sessions/{sitterId}/
  ├── sitterId: string
  ├── createdAt: timestamp
  ├── status: "idle" | "running" | "finished" | "stopped"
  ├── duration: number (seconds)
  ├── startedAt: timestamp | null
  └── waiters: [{ waiterId: string, deviceName: string, joinedAt: timestamp }]
```

### Security Rules (basic):
- Only authenticated users (anonymous) can read/write their own session
- WAITERs can only read sessions they are registered in

---

## 🧩 Key Dependencies (build.gradle)

```kotlin
// Firebase
implementation(platform("com.google.firebase:firebase-bom:32.x.x"))
implementation("com.google.firebase:firebase-firestore-ktx")
implementation("com.google.firebase:firebase-auth-ktx")
implementation("com.google.firebase:firebase-messaging-ktx")

// AdMob
implementation("com.google.android.gms:play-services-ads:23.x.x")

// QR
implementation("com.google.mlkit:barcode-scanning:17.x.x")
implementation("com.journeyapps:zxing-android-embedded:4.x.x")

// Lottie (optional for animations)
implementation("com.airbnb.android:lottie-compose:6.x.x")

// Hilt
implementation("com.google.dagger:hilt-android:2.x.x")
kapt("com.google.dagger:hilt-compiler:2.x.x")

// Compose
implementation(platform("androidx.compose:compose-bom:2024.x.x"))
implementation("androidx.compose.ui:ui")
implementation("androidx.compose.material3:material3")
implementation("androidx.navigation:navigation-compose:2.x.x")
```

---

## 📱 Permissions (AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

---

## 🗂️ Assets to be Provided by Client

| File | Purpose |
|---|---|
| `drawable/ic_sitter.png` | SITTER tile background on Role Selection screen |
| `drawable/ic_waiter.png` | WAITER tile background on Role Selection screen |
| `drawable/anim_man_normal.png` | Normal man on toilet (for Skeleton Fade animation) |
| `drawable/anim_man_skeleton.png` | Skeleton on toilet (for Skeleton Fade animation) |
| `drawable/anim_sandglass_bg.png` | Background for Sandglass Man animation |
| `raw/alarm_sound.mp3` | Alarm sound played when timer ends |

---

## ✅ Development Checklist

- [ ] Firebase project setup (Android app registered)
- [ ] AdMob account + App ID + Ad Unit IDs configured
- [ ] Anonymous Firebase Auth flow
- [ ] Role selection + persistence (DataStore)
- [ ] Firestore session document CRUD
- [ ] QR code generation (SITTER)
- [ ] QR code scanning (WAITER)
- [ ] Real-time Firestore listener on WAITER screen
- [ ] Timer countdown logic (SITTER side)
- [ ] Timer sync to Firestore on START / STOP / FINISH
- [ ] WAITER receives real-time timer state
- [ ] Alarm sound playback on both devices
- [ ] AdMob Banner integration (SITTER + WAITER screens)
- [ ] AdMob Interstitial integration (WAITER — on finish + on stop)
- [ ] Animation Option A: Sandglass Man (Canvas particle system)
- [ ] Animation Option B: Skeleton Fade (AnimatedContent crossfade)
- [ ] Settings screen: manage WAITERs (add / remove)
- [ ] Settings screen: animation toggle
- [ ] Settings screen: language selector
- [ ] Full localization: EN, PL, DE strings
- [ ] Push notifications via FCM (timer alerts in background)
- [ ] Multi-WAITER support (SITTER can have N paired WAITERs)
- [ ] Multi-SITTER support (WAITER can be paired to N SITTERs)
