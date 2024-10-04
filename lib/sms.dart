import 'package:background_sms/background_sms.dart';
import 'package:flutter/material.dart';

import 'package:permission_handler/permission_handler.dart';

class sms extends StatefulWidget {
  const sms({super.key});

  @override
  State<sms> createState() => _smsState();
}

class _smsState extends State<sms> {
 _getPermission() async => await [
        Permission.sms,
      ].request();

  Future<bool> _isPermissionGranted() async =>
      await Permission.sms.status.isGranted;

  _sendMessage(String phoneNumber, String message, {int? simSlot}) async {
    var result = await BackgroundSms.sendMessage(
        phoneNumber: phoneNumber, message: message, simSlot: simSlot);
    if (result == SmsStatus.sent) {
      print("Sent");
    } else {
      print("Failed");
    }
  }

  Future<bool?> get _supportCustomSim async =>
      await BackgroundSms.isSupportCustomSim;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Send Sms'),
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.send),
          onPressed: () async {
            if (await _isPermissionGranted()) {
              if ((await _supportCustomSim)!){
                _sendMessage("8154972879", "Your friend/relative is in distress", simSlot: 2);
                _sendMessage("7011521587", "Your friend/relative is in distress", simSlot: 2);
                _sendMessage("8708928829", "Your friend/relative is in distress", simSlot: 2);
                 _sendMessage("6006019677", "Your friend/relative is in distress", simSlot: 2);
                 }
                
              else
                _sendMessage("7200305508", "Hello");
            } else
              _getPermission();
          },
        ),
      ),
    );
  }
}