import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:twilio_programmable_video_example/debug.dart';
import 'package:twilio_programmable_video_example/room/join_room_page.dart';
import 'package:twilio_programmable_video_example/shared/services/backend_service.dart';

void main() {
  Debug.enabled = true;
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(TwilioProgrammableVideoExample());
}

class TwilioProgrammableVideoExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Provider<BackendService>(
      create: (_) => FirebaseFunctions.instance,
      child: MaterialApp(
        title: 'Twilio Programmable Video',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          appBarTheme: AppBarTheme(
            color: Colors.blue,
            textTheme: TextTheme(
              headline6: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ),
        home: JoinRoomPage(),
      ),
    );
  }
}
