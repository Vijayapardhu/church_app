# Christ's Chapel Church App

A comprehensive Flutter application designed for Christ's Chapel Church to connect with its community, share spiritual content, and facilitate prayer requests and worship.

## 📱 Features

### Core Features
- **User Authentication**: Secure sign-in with Google authentication and role-based access (Admin, Pastor, Member)
- **Prayer Requests**: Submit, view, and manage prayer requests with image support
- **Prayer Approval System**: Pastor-specific feature to review and approve prayer requests
- **Bible**: Built-in Bible reader for spiritual study
- **Songs & Worship**: Browse and play worship songs with audio player integration
- **Song Lyrics**: View lyrics for worship songs
- **Gallery**: Share and view church event photos and moments
- **Daily Inspiration**: Receive daily spiritual messages and inspiration
- **Profile Management**: Manage user profiles and settings
- **User Management**: Admin panel for managing church members and roles
- **Push Notifications**: Stay updated with church announcements via Firebase Cloud Messaging

### Technical Features
- Multi-platform support (Android, iOS, Web, Windows, macOS, Linux)
- Offline capability with cached images
- Real-time database synchronization with Cloud Firestore
- Cloud storage for images and media files
- Audio recording and playback
- File picking and image selection
- Responsive design with Google Fonts and animations

## 🛠 Technologies Used

### Frontend Framework
- **Flutter**: Cross-platform mobile, web, and desktop framework
- **Dart SDK**: >=3.0.0 <4.0.0

### Firebase Services
- **Firebase Core**: App initialization and configuration
- **Firebase Authentication**: User authentication with Google Sign-In
- **Cloud Firestore**: NoSQL cloud database for real-time data
- **Firebase Storage**: Cloud storage for images and files
- **Firebase Cloud Messaging**: Push notifications

### Key Dependencies
- **Provider**: State management
- **Just Audio**: Audio playback for worship songs
- **Cached Network Image**: Efficient image loading and caching
- **Image Picker**: Camera and gallery image selection
- **File Picker**: File selection functionality
- **Record**: Audio recording capabilities
- **Google Fonts**: Custom typography
- **Flutter Animate**: Smooth animations
- **WebView Flutter**: In-app web content display
- **URL Launcher**: Open external links
- **Intl**: Internationalization and date formatting

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (>=3.0.0)
- [Dart SDK](https://dart.dev/get-dart) (>=3.0.0)
- [Git](https://git-scm.com/)
- A code editor (VS Code, Android Studio, or IntelliJ IDEA recommended)
- For Android development: Android Studio with Android SDK
- For iOS development: Xcode (macOS only)
- For Web development: Chrome browser
- A Firebase account and project

## 🚀 Installation

### 1. Clone the Repository

```bash
git clone https://github.com/Vijayapardhu/church_app.git
cd church_app
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Firebase Setup

This app requires Firebase configuration. Follow these steps:

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)

2. Enable the following Firebase services in your project:
   - Authentication (enable Google Sign-In provider)
   - Cloud Firestore
   - Firebase Storage
   - Cloud Messaging

3. Add your app to the Firebase project:
   - For Android: Download `google-services.json` and place it in `android/app/`
   - For iOS: Download `GoogleService-Info.plist` and add it to the Xcode project
   - For Web: Configure web app settings

4. The `firebase_options.dart` file is already configured, but you may need to update it with your project credentials using FlutterFire CLI:

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for your project
flutterfire configure
```

5. Set up Firestore security rules and create the following collections:
   - `users` - User profiles with role field (member/pastor/admin)
   - `prayers` - Prayer requests
   - `gallery` - Gallery items
   - `songs` - Worship songs
   - `inspirations` - Daily inspirations

### 4. Configure App Icon (Optional)

The app icon is configured to use `assets/images/logo2.png`. To generate app icons:

```bash
dart run flutter_launcher_icons
```

## 🎯 Running the App

### Run on Android Emulator/Device

```bash
flutter run -d android
```

### Run on iOS Simulator/Device (macOS only)

```bash
flutter run -d ios
```

### Run on Web

```bash
flutter run -d chrome
```

### Run on Desktop

```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

### Build for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

## 📁 Project Structure

```
church_app/
├── android/              # Android platform-specific code
├── ios/                  # iOS platform-specific code
├── web/                  # Web platform-specific code
├── windows/              # Windows platform-specific code
├── macos/                # macOS platform-specific code
├── linux/                # Linux platform-specific code
├── lib/
│   ├── main.dart        # App entry point
│   ├── firebase_options.dart  # Firebase configuration
│   ├── models/          # Data models
│   │   ├── gallery_item.dart
│   │   ├── inspiration.dart
│   │   └── prayer.dart
│   ├── screens/         # UI screens
│   │   ├── home_screen.dart
│   │   ├── login_screen.dart
│   │   ├── sign_in_screen.dart
│   │   ├── prayer_requests_screen.dart
│   │   ├── prayer_approval_screen.dart
│   │   ├── bible_screen.dart
│   │   ├── songs_screen.dart
│   │   ├── song_lyrics_screen.dart
│   │   ├── gallery_screen.dart
│   │   ├── daily_inspiration_screen.dart
│   │   ├── profile_screen.dart
│   │   └── user_management_screen.dart
│   ├── services/        # Business logic and Firebase services
│   │   ├── auth_service.dart
│   │   ├── firestore_service.dart
│   │   └── storage_service.dart
│   └── widgets/         # Reusable UI components
├── assets/
│   ├── images/          # App images and logo
│   └── bible_books_json/  # Bible data
├── test/                # Unit and widget tests
├── functions/           # Firebase Cloud Functions
├── pubspec.yaml         # Project dependencies
└── README.md           # This file
```

## 👥 User Roles

The app supports three user roles:

1. **Member**: Regular church members can view content, submit prayer requests, and browse the gallery
2. **Pastor**: Can approve/reject prayer requests and manage spiritual content
3. **Admin**: Full access to user management and all features

## 🔒 Security

- User authentication is handled through Firebase Authentication
- Firestore security rules should be configured to protect user data
- Role-based access control for sensitive features

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 Development Notes

- The app uses Provider for state management
- Firebase is the backend for authentication, database, and storage
- Audio features require platform-specific permissions
- Image picker and file picker require platform-specific permissions
- Push notifications require proper Firebase Cloud Messaging setup

## 🐛 Troubleshooting

### Common Issues

1. **Firebase configuration errors**: Ensure all Firebase configuration files are properly placed and FlutterFire is configured correctly
2. **Build errors**: Run `flutter clean` and `flutter pub get` to refresh dependencies
3. **Permission errors**: Check that all required permissions are added to platform-specific files (AndroidManifest.xml for Android, Info.plist for iOS)

## 📄 License

This project is private and intended for use by Christ's Chapel Church. All rights reserved.

## 📧 Contact

For questions or support, please contact the development team or church administration.

---

**Version**: 1.0.0+1

Built with ❤️ using Flutter
