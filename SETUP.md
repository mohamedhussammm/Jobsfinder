# ShiftSphere - Setup & Installation Guide

## ✅ Prerequisites

- **Flutter**: 3.10.1 or higher
- **Dart**: 3.10.1 or higher  
- **Android Studio** or **Xcode** (for running on devices)
- **Git** (for version control)

## 🚀 Initial Setup

### 1. Install Flutter

**Windows:**
```bash
# Download Flutter SDK from https://flutter.dev/docs/get-started/install/windows
# Extract to a desired location (e.g., C:\flutter)
# Add to PATH environment variable
```

**macOS:**
```bash
brew install flutter
```

**Verify Installation:**
```bash
flutter --version
dart --version
```

### 2. Clone/Navigate to Project

```bash
cd shiftsphere
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Generate Code

The project uses code generation for JSON serialization. Run:

```bash
flutter pub run build_runner build
```

Or watch mode (auto-regenerate on changes):
```bash
flutter pub run build_runner watch
```

### 5. Verify Setup

```bash
flutter doctor
# Should show: ✓ Flutter, ✓ Android toolchain, ✓ Xcode (macOS)
```

## 🏃 Running the App

### Android
```bash
flutter run -d android
# or specific emulator
flutter run -d "emulator-5554"
```

### iOS
```bash
cd ios
pod install
cd ..
flutter run -d ios
```

### Web (for testing only)
```bash
flutter run -d chrome
```

## 🔧 Supabase Configuration

### Already Configured
```
URL: https://qxdgkioixstyigbvohmc.supabase.co
Key: sb_publishable_2GrDJ_wAU1ofjJI1HGy7Kw_BDhMSOWt
```

The credentials are initialized in `lib/core/supabase/supabase_client.dart`

### Custom Configuration (Optional)
Edit `lib/core/supabase/supabase_client.dart`:

```dart
Future<void> initializeSupabase() async {
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_KEY',
  );
}
```

## 📦 Project Structure After Setup

```
shiftsphere/
├── android/           # Android native code
├── ios/              # iOS native code
├── lib/              # Dart code
│   ├── core/
│   ├── models/
│   ├── controllers/
│   ├── views/
│   ├── routes/
│   └── main.dart
├── pubspec.yaml      # Dependencies
├── pubspec.lock      # Lock file
└── README.md
```

## 🎯 First Run Checklist

- [ ] Flutter installed correctly
- [ ] Supabase credentials configured
- [ ] `flutter pub get` completed
- [ ] `build_runner build` completed
- [ ] Device/emulator connected
- [ ] `flutter run` successful
- [ ] App opens to Event Browse Screen

## 🔨 Development Commands

### Clean and rebuild
```bash
flutter clean
flutter pub get
flutter pub run build_runner build
flutter run
```

### Hot reload (during development)
Press `r` in terminal while app is running

### Full hot restart
Press `R` in terminal while app is running

### Format code
```bash
dart format lib/
```

### Analyze code
```bash
flutter analyze
```

### Run tests
```bash
flutter test
```

## 📝 Environment Variables (Optional)

Create `.env` file in project root:
```
SUPABASE_URL=https://qxdgkioixstyigbvohmc.supabase.co
SUPABASE_ANON_KEY=sb_publishable_2GrDJ_wAU1ofjJI1HGy7Kw_BDhMSOWt
```

Load with `flutter_dotenv`:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

await dotenv.load(fileName: ".env");
String url = dotenv.env['SUPABASE_URL']!;
String key = dotenv.env['SUPABASE_ANON_KEY']!;
```

## 🐛 Troubleshooting

### "build_runner" not found
```bash
flutter pub add dev:build_runner
flutter pub run build_runner build
```

### Generated files not updating
```bash
flutter pub run build_runner clean
flutter pub run build_runner build
```

### Supabase connection error
- Verify internet connection
- Check credentials in `supabase_client.dart`
- Ensure Supabase project is active
- Check Supabase dashboard for errors

### Android build fails
```bash
cd android
./gradlew clean
cd ..
flutter run
```

### iOS build fails
```bash
cd ios
rm -rf Pods/ Podfile.lock
pod install
cd ..
flutter run
```

### Port already in use
```bash
# Find and kill process on port 5037
# Windows:
netstat -ano | findstr :5037
taskkill /PID <PID> /F

# macOS/Linux:
lsof -ti :5037 | xargs kill -9
```

## 📱 Device Testing

### List connected devices
```bash
flutter devices
```

### Run on specific device
```bash
flutter run -d <device_id>
```

### Create Android emulator
```bash
flutter emulators --create --name pixel_5
flutter emulators --launch pixel_5
```

## 🎓 Learning Resources

- [Flutter Official Docs](https://flutter.dev/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Riverpod Documentation](https://riverpod.dev)
- [Supabase Documentation](https://supabase.com/docs)
- [Material Design](https://material.io/design)

## 📦 Useful Plugins

Already included:
- `supabase_flutter` - Backend
- `flutter_riverpod` - State management
- `go_router` - Navigation
- `freezed` - Code generation
- `json_serializable` - JSON handling

Add more with:
```bash
flutter pub add package_name
```

## ✨ Next Steps

1. **Explore the code** - Understand the MVC structure
2. **Read DEVELOPMENT.md** - Learn development patterns
3. **Create your first feature** - Follow the patterns in existing code
4. **Test with Supabase** - Use real data
5. **Build UI screens** - Extend the views

## 🚀 Production Build

### Android Release
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS Release
```bash
flutter build ios --release
```

### Web Release
```bash
flutter build web --release
```

## 📞 Support

If you encounter issues:
1. Check the error message carefully
2. Search GitHub issues for similar problems
3. Read the relevant documentation
4. Check Supabase dashboard for errors
5. Test with `flutter doctor` to verify setup

---

**Happy coding! 🎉**
