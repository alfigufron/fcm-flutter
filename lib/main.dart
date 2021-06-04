import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notification_permissions/notification_permissions.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage msg) async {
  await Firebase.initializeApp();
}

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'Hight Importance Notification',
  'This channel is used for important notifications.',
  importance: Importance.high
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  await flutterLocalNotificationsPlugin
    .resolvePlatformSpecificImplementation
      <AndroidFlutterLocalNotificationsPlugin>
      ()?.createNotificationChannel(channel);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FCM Flutter',
      home: Home()
    );
  }
}

class Home extends StatefulWidget {
  Home({Key key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool permNotification = true;
  bool alertPerm = false;

  var permGranted = "granted";
  var permDenied = "denied";
  var permUnknown = "unknown";
  var permProvisional = "provisional";

  void checkNotificationPermStatus() async {
    final status = await NotificationPermissions.getNotificationPermissionStatus();

    (status == PermissionStatus.granted)
      ? permNotification = true
      : permNotification = false;

    setState(() {});
  }
  
  @override
  void initState() { 
    super.initState();

    checkNotificationPermStatus();

    var initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

    var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid
    );

    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification notification = message.notification;
      AndroidNotification android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channel.description,
                icon: android?.smallIcon,
              ),
            ));
      }
    });

    getToken();
  }

  getToken() async {
    print('[GET] token');
    String token = await FirebaseMessaging.instance.getToken();
    print("[RESPONSE] token : $token");
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!alertPerm && !permNotification) {
        checkNotificationPermStatus();

        print("[DEBUG] $permNotification");

        showAlertPerm(context);
        
        setState(() => alertPerm = true);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("FCM Notification Demo"),
              TextButton(
                onPressed: () {
                  NotificationPermissions.requestNotificationPermissions();
                },
                child: Text("Permission Notification")
              ),
              TextButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (BuildContext context) => 
                    AlertDialog(
                      title: Text("Permission Notification"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            
                            NotificationPermissions.requestNotificationPermissions();
                          },
                          child: Text("Yes")
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text("No")
                        ),
                      ],
                    )
                  ),
                child: Text("Permission Notification with Dialog")
              ),
            ],
          )
        )
      ),
    );
  }

  void showAlertPerm(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => 
        AlertDialog(
          title: Text("Permission Notification"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                
                NotificationPermissions.requestNotificationPermissions();
              
              },
              child: Text("Yes")
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("No")
            ),
          ],
        )
      );
  }
}