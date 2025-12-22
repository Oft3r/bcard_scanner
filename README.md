# 🪪 B-Card Scanner

**B-Card Scanner** is a modern, professional Flutter application designed to digitize, organize, and manage business cards using AI-powered text recognition (OCR) and geolocation services.

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![SQLite](https://img.shields.io/badge/sqlite-%2307405e.svg?style=for-the-badge&logo=sqlite&logoColor=white)

---

## 🌟 Key Features

- **🔍 Smart OCR Scanning**: Powered by Google ML Kit to automatically extract contact details (Name, Title, Company, Phone, Email, etc.) from physical cards.
- **🗺️ Interactive Map View**: Visualize the physical locations of your contacts on a map using integrated geocoding services.
- **📱 Contact Management**: 
    - Organize cards into categories.
    - Tag favorite contacts for quick access.
    - Full-text search across all scanned cards.
- **🔗 Quick Actions**: Call, email, or visit websites directly from the contact's profile.
- **🔳 QR Code Sharing**: Generate and scan QR codes to share contact information instantly.
- **🔒 Local-First Privacy**: All data is stored securely on your device using an SQLite database.
- **🎨 Modern UI**: Clean, professional interface built with Material 3 and custom aesthetics.

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.10.x or higher)
- [Dart SDK](https://dart.dev/get-started/sdk)
- Android Studio / VS Code with Flutter extensions.

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/bcard_scanner.git
   cd bcard_scanner
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

## 🛠️ Tech Stack

- **Frontend**: [Flutter](https://flutter.dev) (Dart)
- **OCR Engine**: [Google ML Kit Text Recognition](https://pub.dev/packages/google_mlkit_text_recognition)
- **Local Database**: [sqflite](https://pub.dev/packages/sqflite)
- **Maps**: [flutter_map](https://pub.dev/packages/flutter_map) & [latlong2](https://pub.dev/packages/latlong2)
- **Imaging**: [image_picker](https://pub.dev/packages/image_picker)
- **Communication**: [url_launcher](https://pub.dev/packages/url_launcher) & [share_plus](https://pub.dev/packages/share_plus)
- **Utilities**: [intl](https://pub.dev/packages/intl), [uuid](https://pub.dev/packages/uuid), [qr_flutter](https://pub.dev/packages/qr_flutter)

## 📂 Project Structure

```text
lib/
├── data/       # Database helpers and persistence
├── models/     # Data entities (BusinessCard)
├── screens/    # Main UI views (Home, Map, Details)
├── services/   # Business logic (Geocoding, OCR)
├── utils/      # Constants and helpers
├── widgets/    # Reusable UI components
└── main.dart   # App entry point
```

## 📜 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

*Developed with ❤️ as a professional networking solution.*
