# 🐱 Cat's Commute

A personal smart commute planner for Cat — built with Flutter for Android.

---

## How it works

### Sunday evenings (9pm notification)
Cat gets a notification: *"New week coming up!"*
Opening the app brings up the **weekly planning screen** where she taps which days she's going into the office next week and sets an arrival time for each day (default 8:30am, tappable to change).

- If Monday is selected → she sets the arrival time right there
- If no days are selected → the app thanks her and wishes her goodnight
- When confirmed, the app schedules all the relevant evening check-ins for the week

### Evening before each office day (9pm notification)
The app sends: *"Are you still heading into the office tomorrow?"*

Opening it steps through three quick questions:
1. **Still going in?** → Yes / No
2. **What time would you like to arrive?** → tap to pick
3. **Open to cycling?** → Yes, if the weather's good / No, tube it is

Then: *"Goodnight, Cat!"* with a summary of what to expect.

If she says she's **not going in**, the app updates her week plan and reschedules notifications.

### Morning of an office day (notification at her chosen time, default 7am)
The app shows a recommendation: **🚲 Cycle day**, **🚇 Tube day**, or **☁️ Could go either way**.

The decision is based on:
- Rain forecast during her commute window (calculated from her arrival time minus cycling time)
- Temperature vs her minimum cycling threshold
- Whether she said she's open to cycling the night before
- Whether she's heading straight out after work (asked in the morning card)

Plus live **Northern Line status** — if there are severe disruptions, the app suggests her three alternative tube options: Clapham Common, Clapham South, or Brixton (Victoria line).

### Manual edits anytime
From the home screen, she can tap **"Edit this week"** to change office days or arrival times at any point.

---

## Routes

| Route | When |
|-------|------|
| 🚲 Cycle (Rodenhurst Rd → Scrutton St) | ~40 min, weather permitting |
| 🚇 Clapham Common → Northern line → Old Street | Standard tube |
| 🚇 Clapham South → Northern line → Old Street | One stop south, similar walk |
| 🚇 Brixton → Victoria line → King's Cross → Old Street | Northern line disrupted |

---

## Setup

### 1. Install Flutter
https://docs.flutter.dev/get-started/install

### 2. Get a free weather API key
1. Sign up at [openweathermap.org](https://openweathermap.org)
2. Go to **API Keys** in your account dashboard
3. Copy your key (it activates within ~10 minutes of signing up)

### 3. Build and install on Cat's phone
```bash
cd cats_commute
flutter pub get
flutter build apk --release
```
Transfer `build/app/outputs/flutter-apk/app-release.apk` to Cat's phone and install it. Or connect her phone via USB and run:
```bash
flutter run --release
```

### 4. First-time setup in the app
1. Open the app → tap **Settings** ⚙️
2. Paste the OpenWeatherMap API key
3. Set rain threshold and minimum temperature to her liking
4. Tap **Save**
5. Done — on Sunday evening the app will prompt her to plan her week

---

## Settings reference

| Setting | Default | Description |
|---------|---------|-------------|
| Rain threshold | 30% | Max rain probability before recommending the tube |
| Min cycling temp | 7°C | Too cold to cycle below this |
| Cycling time | 40 min | Update once Cat has timed the commute! |
| Typical office days | Tue, Thu | Pre-selected on the Sunday planning screen |
| Morning notification | 7:00am | Nudge on office day mornings |

Evening notifications are fixed at **9pm** (Sunday planning + pre-office-day check-ins).

---

## Tech stack
- **Flutter** (Dart) — Android app
- **OpenWeatherMap API** (free tier) — weather forecasts
- **TfL Unified API** — live Northern Line status (no key required)
- **flutter_local_notifications** — scheduled notifications
- **shared_preferences** — local data storage

---

Made with ❤️ for Cat.
