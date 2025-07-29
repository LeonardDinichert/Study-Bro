# SchoolAssisstant

SchoolAssisstant is a SwiftUI app that helps you focus, keep notes and stay motivated while studying. It stores data in Firebase and uses FCM to deliver reminders across your devices.

## Features
- **Pomodoro Sessions** – Start timed work sessions with optional meditation and automatic Work Focus.
- **Notes & Revision** – Capture quick notes, organise them by category and review them using spaced repetition.
- **Statistics** – Check your daily study minutes and current streak in beautiful charts.
- **Tasks** – Create tasks with due dates and receive local notifications.
- **Chatbot** – Ask questions to an integrated Llama‑3 model.
- **Gamification** – Earn XP and gems, collect trophies and compare with friends on a weekly leaderboard.
- **Push Notifications** – Receive study reminders and friend nudges via Firebase Cloud Messaging.
- **Profile Management** – Sign up, edit your profile and customise your study branches.

## Setup
1. Install Xcode 15 or later (iOS 16+).
2. Clone this repository and open `Study Bro.xcodeproj`.
3. Add your Firebase `GoogleService-Info.plist` inside `Study Bro/Resources`.
4. Build and run on a simulator or physical device.

Firestore collections used by the app are documented in `UserManager`, `NotesManager` and `TaskManager`.

## Design System
The interface follows Apple's guidelines with an orange accent defined in `AppTheme`.

- **Primary:** `#FFB660` with tint and shade variations.
- **Components:** `.glassEffect()` cards and rounded buttons.
- **Accessibility:** Supports Dynamic Type and large tap targets.

