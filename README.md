# LEO Robot 🤖

**AI-Powered Talking Robot with Flutter Mobile App**

A voice-controlled AI robot that listens, thinks, and talks using:
- Flutter mobile app with animated eyes
- Google Gemini API for AI responses
- Bluetooth HC-05 communication with Arduino
- MAX98357A I2S audio output

## Features

✅ **Voice Input** - Record from phone microphone  
✅ **AI Processing** - Gemini API for intelligent responses  
✅ **Voice Output** - Google Text-to-Speech  
✅ **Bluetooth Control** - HC-05 wireless communication  
✅ **Animated Eyes** - Visual feedback (listening, processing, talking)  

## Hardware Required

- Arduino UNO R3
- HC-05 Bluetooth Module
- MAX98357A I2S Audio Codec
- Speaker
- Smartphone (Android 5.0+)

## Installation

1. **Get Flutter SDK**: https://flutter.dev/docs/get-started/install

2. **Clone or download this project**

3. **Get dependencies**:
   ```bash
   flutter pub get
   ```

4. **Add Gemini API key**:
   - Get key from: https://aistudio.google.com/app/apikey
   - Edit `lib/main.dart`
   - Replace `GEMINI_API_KEY` with your actual key

5. **Connect Bluetooth**:
   - Pair HC-05 in phone Bluetooth settings

6. **Run app**:
   ```bash
   flutter run
   ```

## Arduino Setup

Upload `arduino_leo_robot.ino` to your Arduino UNO with:
- HC-05 Bluetooth Module
- MAX98357A I2S Audio Codec

## Building APK

```bash
flutter build apk --release
```

Or use CodeMagic for automated builds:
1. Push code to GitHub
2. Connect GitHub to CodeMagic
3. CodeMagic builds APK automatically

## Configuration

### Add Gemini API Key

Edit `lib/main.dart`:
```dart
final String GEMINI_API_KEY = 'YOUR_KEY_HERE';
```

### HC-05 Bluetooth Wiring
```
HC-05 VCC  → Arduino 5V
HC-05 GND  → Arduino GND
HC-05 TX   → Arduino RX (Pin 0)
HC-05 RX   → Arduino TX (Pin 1)
```

### MAX98357A I2S Audio
```
MAX VCC    → Arduino 5V
MAX GND    → Arduino GND
MAX DIN    → Arduino Pin 11
MAX BCLK   → Arduino Pin 9
MAX LRCLK  → Arduino Pin 6
MAX SD     → Arduino Pin 7
```

## License

MIT License

## Support

For issues, check the documentation or GitHub issues.

---

**Made with ❤️ using Flutter + Gemini AI + Arduino**
