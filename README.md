# SkillRiseApp

A Flutter-based learning and career development application that helps users discover learning paths, track progress, access AI-powered guidance, manage tasks, and prepare for careers.

---

## Features

* User Authentication with Firebase
* AI Mentor Integration (Groq API)
* Learning Roadmaps
* Course Suggestions
* Daily Planner
* Weekly Knowledge Checks
* Career Guidance
* Resume Builder & Download
* Progress Tracking
* Notifications
* Analytics Dashboard

---

# Project Structure

```text
lib/
├── models/
├── screens/
├── services/
├── widgets/
├── main.dart

android/
web/
windows/

pubspec.yaml
firebase.json
```

---

# Requirements

Before running the project, install:

1. Flutter SDK
2. Android Studio
3. Android SDK
4. Git
5. Firebase Project
6. Groq API Key

---

# Clone the Project

```bash
git clone https://github.com/tayyabsajjad76/SkillRiseApp.git
cd SkillRiseApp
```

---

# Install Dependencies

```bash
flutter pub get
```

---

# Firebase Setup

This project uses Firebase.

Make sure the following file exists:

```text
android/app/google-services.json
```

If missing:

1. Open Firebase Console
2. Select the project
3. Open Project Settings
4. Select Android App
5. Download google-services.json
6. Place it inside:

```text
android/app/
```

---

# Groq API Setup

Open:

```text
lib/services/ai_service.dart
```

Find:

```dart
static const String _apiKey = 'YOUR_GROQ_API_KEY';
```

Replace with:

```dart
static const String _apiKey = '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';
```

Example:

```dart
static const String _apiKey = 'gsk_xxxxxxxxxxxxxxxxx';
```

Never commit your real API key to GitHub.

---

# Running the Application

Check Flutter installation:

```bash
flutter doctor
```

Run the application:

```bash
flutter run
```

---

# Build APK

Debug APK:

```bash
flutter build apk
```

Release APK:

```bash
flutter build apk --release
```

APK location:

```text
build/app/outputs/flutter-apk/app-release.apk
```

---

# Build App Bundle For Play Store

```bash
flutter build appbundle
```

Generated file:

```text
build/app/outputs/bundle/release/app-release.aab
```

---

# Common Commands

Get packages:

```bash
flutter pub get
```

Update packages:

```bash
flutter pub upgrade
```

Clean project:

```bash
flutter clean
```

Reinstall packages:

```bash
flutter clean
flutter pub get
```

Check devices:

```bash
flutter devices
```

---

# Moving Project To Another Laptop

1. Install Flutter
2. Install Android Studio
3. Clone Repository

```bash
git clone https://github.com/tayyabsajjad76/SkillRiseApp.git
```

4. Open project
5. Run:

```bash
flutter pub get
```

6. Add:

   * google-services.json
   * Groq API Key

7. Run:

```bash
flutter run
```

---

# Troubleshooting

## API Errors

Check:

* Internet connection
* Correct Groq API key
* API quota

---

## Firebase Errors

Check:

```text
android/app/google-services.json
```

exists and belongs to the correct Firebase project.

---

## Packages Not Found

Run:

```bash
flutter clean
flutter pub get
```

---

## Android Build Errors

Run:

```bash
flutter doctor
```

Fix all issues reported.

---

# Important Files

| File                             | Purpose                 |
| -------------------------------- | ----------------------- |
| pubspec.yaml                     | Dependencies            |
| lib/main.dart                    | Application Entry Point |
| lib/services/ai_service.dart     | Groq AI Integration     |
| firebase.json                    | Firebase Configuration  |
| android/app/google-services.json | Firebase Android Setup  |

---

# Backup Checklist

Before formatting a PC or uninstalling Android Studio:

* Push latest code to GitHub
* Verify repository is updated
* Backup Firebase project access
* Backup Groq API key
* Backup signing key (.jks) if publishing to Play Store

---

# Author

Tayyab Sajjad

SkillRiseApp - Learning and Career Development Platform
