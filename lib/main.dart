import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:convert';

void main() {
  runApp(const LeoRobotApp());
}

class LeoRobotApp extends StatelessWidget {
  const LeoRobotApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LEO Robot',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LeoScreen(),
    );
  }
}

class LeoScreen extends StatefulWidget {
  const LeoScreen({Key? key}) : super(key: key);

  @override
  State<LeoScreen> createState() => _LeoScreenState();
}

class _LeoScreenState extends State<LeoScreen> with TickerProviderStateMixin {
  late stt.SpeechToText _speechToText;
  late FlutterTts _flutterTts;
  late FlutterBluetoothSerial _bluetooth;
  
  late AnimationController _eyeAnimationController;
  late AnimationController _blinkAnimationController;
  
  String _recognizedText = '';
  String _apiResponse = '';
  String _currentState = 'idle';
  bool _isListening = false;
  bool _isSpeaking = false;
  BluetoothConnection? _bluetoothConnection;
  bool _isBluetoothConnected = false;

  final String GEMINI_API_KEY = String.fromEnvironment('GEMINI_API_KEY',
      defaultValue: 'AIzaSyDF5mTo694pbzSISMKAMO_rSt1Eu0nqBuY');
  late GenerativeModel _generativeModel;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _setupAnimations();
  }

  void _initializeServices() async {
    await _requestPermissions();

    _speechToText = stt.SpeechToText();
    await _speechToText.initialize(
      onError: (error) {
        print('Speech to Text Error: $error');
        _showError('Microphone Error: $error');
      },
      onStatus: (status) {
        print('Speech Status: $status');
      },
    );

    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);

    _flutterTts.setStartHandler(() {
      setState(() => _isSpeaking = true);
      _updateLeoState('talking');
    });

    _flutterTts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
      _updateLeoState('idle');
    });

    _bluetooth = FlutterBluetoothSerial.instance;
    _setupBluetooth();

    _generativeModel = GenerativeModel(
      model: 'gemini-pro',
      apiKey: GEMINI_API_KEY,
    );
  }

  void _setupAnimations() {
    _eyeAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _blinkAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
    await Permission.bluetooth.request();
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothScan.request();
  }

  void _setupBluetooth() async {
    try {
      List<BluetoothDevice> devices = [];
      try {
        devices = await _bluetooth.getBondedDevices();
      } catch (e) {
        print('Error getting bonded devices: $e');
      }

      print('Available Bluetooth Devices: ${devices.length}');
      for (var device in devices) {
        print('Device: ${device.name} (${device.address})');
      }

      _connectToHC05(devices);
    } catch (e) {
      print('Bluetooth Setup Error: $e');
      _showError('Bluetooth Error: $e');
    }
  }

  void _connectToHC05(List<BluetoothDevice> devices) {
    BluetoothDevice? hc05Device = devices.firstWhere(
      (device) => device.name?.contains('HC-05') ?? false,
      orElse: () => devices.isNotEmpty ? devices.first : null as BluetoothDevice,
    );

    if (hc05Device != null) {
      BluetoothConnection.toAddress(hc05Device.address).then((connection) {
        setState(() {
          _bluetoothConnection = connection;
          _isBluetoothConnected = true;
        });
        print('Connected to ${hc05Device.name}');
        _showMessage('Connected to LEO');
      }).catchError((error) {
        print('Bluetooth Connection Error: $error');
        _showError('Connection Failed: $error');
      });
    } else {
      _showError('HC-05 device not found. Please pair it first.');
    }
  }

  Future<void> _startListening() async {
    if (!_isListening && _speechToText.isAvailable) {
      setState(() {
        _isListening = true;
        _recognizedText = '';
        _currentState = 'listening';
      });

      _updateLeoState('listening');

      _speechToText.listen(
        onResult: (result) {
          setState(() {
            _recognizedText = result.recognizedWords;
          });
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'en_US',
      );
    }
  }

  Future<void> _stopListening() async {
    if (_isListening) {
      _speechToText.stop();
      setState(() => _isListening = false);

      if (_recognizedText.isNotEmpty) {
        print('Recognized: $_recognizedText');
        _updateLeoState('processing');
        await _processWithGemini(_recognizedText);
      }
    }
  }

  Future<void> _processWithGemini(String userInput) async {
    try {
      setState(() => _currentState = 'processing');

      final prompt = '''
You are LEO, a friendly AI robot assistant. 
Keep your responses concise and friendly (2-3 sentences max).
User said: "$userInput"

Respond naturally and helpfully.
''';

      final content = [Content.text(prompt)];
      final response = await _generativeModel.generateContent(content);

      final responseText = response.text ?? 'I did not understand that.';
      
      setState(() => _apiResponse = responseText);
      print('Gemini Response: $responseText');

      await _speakResponse(responseText);

      _sendToArduino('TALK_START');

    } catch (e) {
      print('Gemini API Error: $e');
      _showError('API Error: $e');
      setState(() => _currentState = 'idle');
    }
  }

  Future<void> _speakResponse(String text) async {
    try {
      setState(() => _currentState = 'talking');
      _updateLeoState('talking');
      await _flutterTts.speak(text);
    } catch (e) {
      print('TTS Error: $e');
      _showError('Speech Error: $e');
    }
  }

  void _sendToArduino(String command) {
    if (_bluetoothConnection == null || !_isBluetoothConnected) {
      print('Bluetooth not connected');
      _showError('Bluetooth disconnected');
      return;
    }

    try {
      _bluetoothConnection!.output.add(utf8.encode(command + '\n'));
    } catch (e) {
      print('Send Error: $e');
      _showError('Send Error: $e');
    }
  }

  void _updateLeoState(String newState) {
    _sendToArduino('STATE:$newState');
    print('LEO State: $newState');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _eyeAnimationController.dispose();
    _blinkAnimationController.dispose();
    _flutterTts.stop();
    _speechToText.stop();
    _bluetoothConnection?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'LEO',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.cyan,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: 200,
              height: 150,
              child: _buildAnimatedEyes(),
            ),
            const SizedBox(height: 60),

            Text(
              _currentState.toUpperCase(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _getStateColor(),
              ),
            ),
            const SizedBox(height: 20),

            if (_recognizedText.isNotEmpty)
              Container(
                width: 300,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade900,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'You: $_recognizedText',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            if (_apiResponse.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: 300,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.cyan.shade900,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'LEO: $_apiResponse',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 60),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton.extended(
                  onPressed: _isListening ? _stopListening : _startListening,
                  backgroundColor: _isListening ? Colors.red : Colors.blue,
                  label: Text(_isListening ? 'Stop Listening' : 'Listen'),
                  icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
                ),
                const SizedBox(width: 20),

                FloatingActionButton(
                  backgroundColor: _isBluetoothConnected ? Colors.green : Colors.orange,
                  child: Icon(_isBluetoothConnected ? Icons.bluetooth_connected : Icons.bluetooth),
                  onPressed: () {
                    if (!_isBluetoothConnected) {
                      _setupBluetooth();
                      _showMessage('Reconnecting...');
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 30),

            Text(
              'Bluetooth: ${_isBluetoothConnected ? "Connected ✓" : "Disconnected ✗"}',
              style: TextStyle(
                color: _isBluetoothConnected ? Colors.green : Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedEyes() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.cyan, width: 3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildEye(true),
          _buildEye(false),
        ],
      ),
    );
  }

  Widget _buildEye(bool isLeft) {
    return AnimatedBuilder(
      animation: _eyeAnimationController,
      builder: (context, child) {
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Stack(
            children: [
              Positioned(
                left: 30 + (_eyeAnimationController.value * 15 * (isLeft ? -1 : 1)),
                top: 30 + (sin(_eyeAnimationController.value * 3.14) * 10),
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: _getEyeColor(),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              if (_blinkAnimationController.value > 0)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 60 * _blinkAnimationController.value,
                  child: Container(
                    color: Colors.grey.shade900,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Color _getEyeColor() {
    switch (_currentState) {
      case 'listening':
        return Colors.blue;
      case 'processing':
        return Colors.orange;
      case 'talking':
        return Colors.green;
      default:
        return Colors.black;
    }
  }

  Color _getStateColor() {
    switch (_currentState) {
      case 'listening':
        return Colors.blue;
      case 'processing':
        return Colors.orange;
      case 'talking':
        return Colors.green;
      default:
        return Colors.white;
    }
  }
}

double sin(double value) {
  return (value % 6.28).toStringAsFixed(10).hashCode % 2 == 0 ? 
    value.toStringAsFixed(3).contains('.') ? value : 0 : value;
}
