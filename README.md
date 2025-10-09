# Chys - Pet Social Network App

A Flutter-based social networking application designed for pet owners to connect, share, and discover pets in their area.

## 🐾 Features

### Core Features
- **Pet Profiles**: Create and manage detailed pet profiles with photos, information, and behavioral traits
- **Social Feed**: Share posts, stories, and updates about your pets
- **Location-Based Discovery**: Find pets and owners near you using interactive maps
- **Chat System**: Connect with other pet owners through in-app messaging
- **Pet Matching**: Discover compatible pets and potential playmates

### Additional Features
- **Podcast Integration**: Listen to pet-related content and discussions
- **Donation System**: Support pet-related causes and organizations
- **Notifications**: Stay updated with likes, comments, and new connections
- **Settings & Privacy**: Customize your experience and control your data
- **Multi-Platform Support**: Available on iOS, Android, Web, and Desktop

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / VS Code
- iOS Simulator (for iOS development)
- Firebase account (for backend services)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/chys.git
   cd chys
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Add your `google-services.json` to `android/app/`
   - Add your `GoogleService-Info.plist` to `ios/Runner/`
   - Update Firebase configuration in `lib/firebase_options.dart`

4. **Run the app**
   ```bash
   flutter run
   ```

## 📱 App Structure

```
lib/
├── app/
│   ├── core/           # Core utilities, constants, and widgets
│   ├── data/           # Data models and controllers
│   ├── modules/        # Feature modules
│   │   ├── home/       # Home screen and stories
│   │   ├── add_pet/    # Pet registration
│   │   ├── chat/       # Messaging system
│   │   ├── map/        # Location-based features
│   │   ├── posts/      # Social feed
│   │   ├── profile/    # User profiles
│   │   ├── settings/   # App settings
│   │   └── ...         # Other features
│   ├── routes/         # Navigation and routing
│   ├── services/       # API and external services
│   ├── theme/          # App theming
│   └── widget/         # Reusable widgets
├── assets/             # Images, icons, and other assets
└── main.dart           # App entry point
```

## 🛠️ Technologies Used

- **Frontend**: Flutter & Dart
- **Backend**: Firebase (Authentication, Firestore, Storage)
- **Maps**: Google Maps API
- **State Management**: GetX
- **UI Components**: Custom widgets with Material Design
- **Image Handling**: Custom image extensions and SVG support

## 📋 Dependencies

Key dependencies include:
- `get` - State management and routing
- `google_maps_flutter` - Map integration
- `firebase_core` - Firebase services
- `firebase_auth` - Authentication
- `cloud_firestore` - Database
- `firebase_storage` - File storage
- `image_picker` - Image selection
- `geolocator` - Location services

## 🔧 Configuration

### Environment Setup
1. Ensure Flutter is properly installed and configured
2. Set up Firebase project and add configuration files
3. Configure Google Maps API key for location features
4. Set up push notification certificates (iOS/Android)

### Build Configuration
- **Android**: Configure in `android/app/build.gradle.kts`
- **iOS**: Configure in `ios/Runner/Info.plist`
- **Web**: Configure in `web/index.html`

## 🧪 Testing

Run tests using:
```bash
flutter test
```

## 📦 Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request


**Made with ❤️ for pet lovers everywhere**
