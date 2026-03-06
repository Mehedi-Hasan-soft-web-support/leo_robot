# LEO Robot - Quick Setup

## 📁 What's Inside

This is a complete Flutter project ready to use for the LEO Robot app.

```
leo_robot_complete/
├── lib/
│   └── main.dart              ← Your app code
├── android/
│   ├── app/
│   │   ├── build.gradle
│   │   └── src/main/AndroidManifest.xml
│   ├── build.gradle
│   ├── settings.gradle
│   ├── gradle.properties
│   └── gradle/wrapper/
├── pubspec.yaml               ← Dependencies
├── README.md
├── .gitignore
└── analysis_options.yaml
```

## 🚀 Quick Start

### 1. Extract this folder to your computer

### 2. Open Terminal/Command Prompt and navigate to this folder

```bash
cd leo_robot_complete
```

### 3. Install dependencies

```bash
flutter pub get
```

### 4. Add your Gemini API Key

Edit `lib/main.dart` and replace:
```dart
final String GEMINI_API_KEY = String.fromEnvironment('GEMINI_API_KEY',
    defaultValue: 'AIzaSy_YOUR_API_KEY_HERE');
```

Change to your actual key:
```dart
final String GEMINI_API_KEY = String.fromEnvironment('GEMINI_API_KEY',
    defaultValue: 'AIzaSy_YOUR_ACTUAL_API_KEY');
```

### 5. Run the app (local testing)

```bash
flutter run
```

### 6. Or build APK

```bash
flutter build apk --release
```

## 📤 Upload to GitHub

### For GitHub + CodeMagic (Recommended)

1. Create GitHub account: https://github.com
2. Create new repository: Name it "leo_robot"
3. Upload these files to GitHub:
   - `lib/` folder
   - `android/` folder
   - `pubspec.yaml`
   - `pubspec.lock`
   - `.gitignore`
   - `README.md`

4. Go to CodeMagic: https://codemagic.io
5. Connect GitHub repository
6. Add API key as environment variable: `GEMINI_API_KEY`
7. Build APK automatically!

## 📝 Important Files

| File | Purpose |
|------|---------|
| `lib/main.dart` | Your Flutter app code - edit here for customization |
| `pubspec.yaml` | All dependencies - don't remove packages |
| `android/app/build.gradle` | Android build config - keep SDK versions |
| `android/app/src/main/AndroidManifest.xml` | Android permissions |

## ⚙️ Configuration

### API Key (IMPORTANT)

1. Get free key from: https://aistudio.google.com/app/apikey
2. Add to `lib/main.dart` (line ~70)
3. Or set as CodeMagic environment variable

### Bluetooth HC-05

Edit main.dart to change HC-05 device name:
```dart
BluetoothDevice? hc05Device = devices.firstWhere(
  (device) => device.name?.contains('HC-05') ?? false,
);
```

## 🆘 Troubleshooting

**Error: "Flutter SDK not found"**
- Install Flutter: https://flutter.dev/docs/get-started/install
- Add to PATH

**Error: "dependency not found"**
- Run: `flutter pub get`
- Check internet connection

**Error: "Build failed"**
- Delete `build/` folder
- Run: `flutter clean`
- Run: `flutter pub get`
- Try again

## 📱 For GitHub + CodeMagic

Use these guides:
1. `GITHUB_CODEMAGIC_GUIDE.md` - Step by step
2. `SUPER_SIMPLE_CHECKLIST.md` - Quick checklist
3. `VISUAL_WALKTHROUGH.md` - See button locations

## 🎯 Next Steps

1. ✅ Extract this folder
2. ✅ Run `flutter pub get`
3. ✅ Add API key
4. ✅ Pair HC-05 Bluetooth
5. ✅ Run `flutter run` or build APK
6. ✅ Install on phone

## 📞 Questions?

Check the included documentation files for detailed help!

---

**Happy coding! 🚀**
