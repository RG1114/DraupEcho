
import 'package:asar/sms.dart';
import 'package:asar/record.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.microphone.request();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
       
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 150, 137, 172)),
        useMaterial3: true,
      ),
      routes: {
                    // Main page (home)
        '/sms': (context) => sms(),           // SMS page route
        '/recorder': (context) => RecorderPage(), // Audio Recorder page route
      },
      initialRoute: '/recorder', 
    );
  }
}
