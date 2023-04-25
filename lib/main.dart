import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();
  await setupFlutterNotification();
  showFlutterNotification(message);
  developer.log('handling thisss background msg');
}

// late AndroidNotificationChannel channel;

bool isFlutterNotificationInitialized = false;

Future<void> setupFlutterNotification() async {
  if (isFlutterNotificationInitialized) {
    return;
  }

  // channel = const AndroidNotificationChannel(
  //   'unique_channel_id',
  //   'unique_channel_title',
  //   playSound: true,
  //   importance: Importance.high,
  // );

  flnp = FlutterLocalNotificationsPlugin();

  // ....

  var android = const AndroidInitializationSettings('@mipmap/ic_launcher');
  var iOS = const DarwinInitializationSettings();

  var initSettings = InitializationSettings(android: android, iOS: iOS);

  flnp.initialize(initSettings);

  // await flnp
  //     .resolvePlatformSpecificImplementation<
  //         AndroidFlutterLocalNotificationsPlugin>()
  //     ?.createNotificationChannel(channel);

//  Sets the presentation options for Apple notifications when received in the foreground.
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  isFlutterNotificationInitialized = true;
}

void showFlutterNotification(RemoteMessage message) {
  RemoteNotification? notif = message.notification;
  // AndroidNotification? android = message.notification?.android;

  var android = const AndroidNotificationDetails('unique_id', 'unique_name',
      priority: Priority.high, importance: Importance.high);

  var iOs = const DarwinNotificationDetails();

  var platform = NotificationDetails(android: android, iOS: iOs);
  if (notif != null && !kIsWeb) {
    flnp.show(notif.hashCode, notif.title, notif.body, platform);
  }
}

late FlutterLocalNotificationsPlugin flnp;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

  if (!kIsWeb) {
    // if not run on web
    await setupFlutterNotification();
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

// python send message functon
// def sendMessage(to_token, msgTitle, msgBody):
//     send_url = "https://fcm.googleapis.com/fcm/send"
//     server_key = "server key"
//     headers = {"Content-Type":"application/json","Authorization":"key=%s" % server_key}

// body = {
//         "to":to_token,
// you can set data variables/read more on this

// "data": { #don't use this part if notif is to be received while app is teminated
//             "click_action": "FLUTTER_NOTIFICATION_CLICK",
//             "notification_priority": "PRIORITY_HIGH",
//             "sound": "default",
//             "ttl": 60
//           },
//         "notification":{
//             "title":msgTitle,
//             "body":msgBody,
//         }
//     }

//     response = requests.post(send_url,json=body,headers=headers)
//     jsonResponse = json.loads(response.text)
//     print(jsonResponse)

// to the link receiveing send
// {
// "token": "token id",
// "title": "Sending from API 1",
// "body": "This is the notification"
// // }

// you receive

// {
//     "multicast_id": 4872299298184413054,
//     "success": 1,
//     "failure": 0,
//     "canonical_ids": 0,
//     "results": [
//         {
//             "message_id": "0:1682352676903796%95bac80a95bac80a"
//         }
//     ]
// }

class _MyAppState extends State<MyApp> {
  FirebaseMessaging fMessaging = FirebaseMessaging.instance;
  // how do we handle receiving notif when app is terminated, background, or foreground
  // maybe on foreground we can set veibrate and tone only
  //while background and terminated show notification on top
  // what if no internet connection, how will we handle that
  // maybe we can listne to notification received, and if successfully received on app
  // send back saying to app saying true - messages delivered
  Future<void> getFireBaseMessagingToken() async {
    NotificationSettings notificationSettings =
        await fMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    developer.log("${notificationSettings.authorizationStatus}");

    await fMessaging.getToken().then((value) {
      developer.log("Push Token: $value");
    });

    //listen if there is a message
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log("Message data: ${message.data}");

      if (message.notification != null) {
        developer.log("Message notification: ${message.notification?.body}");

        showFlutterNotification(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((event) {
      developer.log("message opened");
      //jump to chat page
    });
  }

  @override
  void initState() {
    getFireBaseMessagingToken();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
