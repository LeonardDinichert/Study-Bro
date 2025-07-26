# SchoolAssisstant

SchoolAssisstant is a study companion app built with SwiftUI. It helps students manage study sessions with a Pomodoro timer, keep personal notes, and track progress over time. The app integrates with Firebase for authentication and data storage.

## Features
- **Pomodoro Timer** – Focused study sessions with optional relaxation break.
- **Learning Notes** – Save quick notes while studying and review them later.
- **Revision Reminders** – View due notes using a spaced-repetition approach.
- **Statistics** – Charts showing daily study minutes.
- **Profile Management** – Sign up, log in, and edit your account details.
- **Tasks** – Keep track of homework and receive reminders.
- **Streaks & Friends** – View your study streak and nudge friends to join you.

## Setup
1. Install Xcode 15 or later (requires iOS 16+).
2. Clone this repository and open `SchoolAssisstant.xcworkspace`.
   If Xcode tries to open the folder as a Swift package, choosing the
   workspace ensures the app project is loaded.
3. Add your Firebase `GoogleService-Info.plist` to enable authentication and storage.
4. Build and run on a simulator or device.

Firebase integration requires setting up Firestore collections referenced in the code. See `UserManager` and `NotesManager` for document structures.

## Design System
The UI follows Apple's Human Interface Guidelines with a soft orange accent.

- **Primary Color:** `#FFB660` with 10% tint and shade for states.
- **Neutrals:** `#F8F8F8` and `#EAEAEB` for cards and separators.
- **Components:** `cardStyle` and `primaryButtonStyle` keep rounded corners and gentle shadows consistent.
- **Accessibility:** Dynamic Type and 44pt touch targets are respected.

