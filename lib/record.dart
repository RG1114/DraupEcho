import 'dart:convert';
import 'dart:typed_data';
import 'package:background_sms/background_sms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';

class AudioRecorder {
  FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool isRecording = false;
  bool isToggling = false;
  String apiUrl = 'http://192.168.136.108:5000/process_audio';
  Timer? _toggleTimer;
  String? _filePath;
  Function sendEmergencySMS; // Callback to trigger SMS from RecorderPage

  AudioRecorder({required this.sendEmergencySMS}); // Pass callback in constructor

  Future<void> startRecording() async {
    await _checkAndRequestPermissions();

    Directory tempDir = await getTemporaryDirectory();
    _filePath = '${tempDir.path}/recording.aac';

    await _recorder.openRecorder();
    await _recorder.startRecorder(
      toFile: _filePath!,
      codec: Codec.aacADTS,
    );
    isRecording = true;

    _toggleTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      if (isRecording) {
        _stopAndSend();
        _startNewRecording();
      }
    });
  }

  Future<void> _stopAndSend() async {
    if (!isRecording) return;

    await _recorder.stopRecorder();
    isRecording = false;

    File audioFile = File(_filePath!);
    Uint8List audioData = await audioFile.readAsBytes();

    if (audioData.isNotEmpty) {
      await _sendToMLModel(audioData);
    }
  }

  Future<void> _startNewRecording() async {
    await _recorder.startRecorder(
      toFile: _filePath!,
      codec: Codec.aacADTS,
    );
    isRecording = true;
    isToggling = true;
  }

  Future<void> _sendToMLModel(Uint8List audioData) async {
    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
    request.files.add(http.MultipartFile.fromBytes(
      'audio',
      audioData,
      filename: 'audio_${DateTime.now().millisecondsSinceEpoch}.aac',
    ));

    var response = await request.send();

    if (response.statusCode == 200) {
      var responseBody = await response.stream.bytesToString();
      var jsonResponse = jsonDecode(responseBody);

      if (jsonResponse['classification'] == 'danger') {
        Fluttertoast.showToast(
          msg: "Danger detected in the audio!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );

        // Automatically trigger SMS when danger is detected
        sendEmergencySMS();
      }
    } else {
      Fluttertoast.showToast(
        msg: "Failed to send audio",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.grey,
        textColor: Colors.white,
      );
    }
  }

  Future<void> stopRecording() async {
    if (isRecording) {
      await _stopAndSend();
      _toggleTimer?.cancel();
      isToggling = false;
    }
    await _recorder.closeRecorder();
  }

  Future<void> _checkAndRequestPermissions() async {
    await Permission.microphone.request();
  }
}

class RecorderPage extends StatefulWidget {
  @override
  _RecorderPageState createState() => _RecorderPageState();
}

class _RecorderPageState extends State<RecorderPage> {
  late AudioRecorder _audioRecorder;
  String buttonText = 'Start Recording';
  TextEditingController _contactController = TextEditingController();
  List<String> _contacts = [];

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder(sendEmergencySMS: _sendMessagesToContacts);
    _loadContacts();
  }

  void _toggleRecording() async {
    if (_audioRecorder.isRecording) {
      await _audioRecorder.stopRecording();
      setState(() {
        buttonText = 'Start Recording';
      });
    } else {
      await _audioRecorder.startRecording();
      setState(() {
        buttonText = 'Stop Recording';
      });
    }
  }

  _getPermission() async => await [Permission.sms, Permission.location].request();

  Future<bool> _isPermissionGranted() async =>
      await Permission.sms.status.isGranted && await Permission.location.status.isGranted;

  Future<void> _sendMessage(String phoneNumber, String message, {int? simSlot}) async {
    var result = await BackgroundSms.sendMessage(phoneNumber: phoneNumber, message: message, simSlot: simSlot);
    if (result == SmsStatus.sent) {
      print("Sent");
    } else {
      print("Failed");
    }
  }

  Future<bool?> get _supportCustomSim async => await BackgroundSms.isSupportCustomSim;

  Future<void> _saveContact(String contact) async {
    if (contact.isNotEmpty) {
      setState(() {
        _contacts.add(contact);
      });
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setStringList('contacts', _contacts);
    }
  }

  Future<void> _loadContacts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _contacts = prefs.getStringList('contacts') ?? [];
    });
  }

  Future<void> _removeContact(int index) async {
    setState(() {
      _contacts.removeAt(index);
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('contacts', _contacts);
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Fluttertoast.showToast(
        msg: "Location services are disabled!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
      );
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(
          msg: "Location permission denied!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
        );
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(
        msg: "Location permissions are permanently denied!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
      );
      return Future.error('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _sendMessagesToContacts() async {
    if (_contacts.isEmpty) {
      Fluttertoast.showToast(
        msg: "No emergency contacts saved!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
      );
      return;
    }

    Position position;
    try {
      position = await _getCurrentLocation();
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to get location: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
      );
      return;
    }

    String locationMessage = 'Location: https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';
    String fullMessage = 'Emergency! Danger detected.\n$locationMessage';

    if (await _isPermissionGranted()) {
      for (String contact in _contacts) {
        await _sendMessage(contact, fullMessage, simSlot: 2);
      }
    } else {
      await _getPermission();
    }
  }

  @override
  void dispose() {
    _audioRecorder._recorder.closeRecorder();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Emergency Recorder'),
        backgroundColor: Colors.redAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _toggleRecording,
              style: ElevatedButton.styleFrom(
                backgroundColor: _audioRecorder.isRecording ? Colors.redAccent : Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                textStyle: TextStyle(fontSize: 20),
              ),
              child: Text(buttonText),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _contactController,
              decoration: InputDecoration(
                labelText: 'Add Emergency Contact',
                border: OutlineInputBorder(),
                hintText: 'Enter phone number',
              ),
              keyboardType: TextInputType.phone,
            ),
            ElevatedButton(
              onPressed: () {
                _saveContact(_contactController.text);
                _contactController.clear();
              },
              child: Text('Save Contact'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _contacts.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_contacts[index]),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeContact(index),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() => runApp(MaterialApp(
      home: RecorderPage(),
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
    ));
