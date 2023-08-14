import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lfgss_mobile/widgets/future_microcosm_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'dart:developer' as developer;

import 'models/huddles.dart';
import 'models/microcosm.dart';
import 'models/profile.dart';
import 'models/search.dart';
import 'models/search_parameters.dart';
import 'models/updates.dart';
import 'widgets/future_huddles_screen.dart';
import 'widgets/future_search_screen.dart';
import 'widgets/future_updates_screen.dart';
import 'widgets/profile_screen.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    int totalExecutions;
    final sharedPreference =
        await SharedPreferences.getInstance(); //Initialize dependency

    try {
      Updates updates = await Updates.root();
      Map<int, String> notifications = await updates.updatesAsNotifications();
      developer.log("New updates: ${notifications.length}");

      for (var entry in notifications.entries) {
        final id = entry.key;
        final description = entry.value;

        const AndroidNotificationDetails androidNotificationDetails =
            AndroidNotificationDetails(
          'lfgss_updates',
          'LFGSS Updates',
          channelDescription: 'Updates from LFGSS',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );

        const NotificationDetails notificationDetails = NotificationDetails(
          android: androidNotificationDetails,
        );

        FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
            await initNotifications();

        await flutterLocalNotificationsPlugin.show(
          id,
          description,
          "$description ($id)",
          notificationDetails,
          payload: "$id, $description",
        );
      }

      totalExecutions = sharedPreference.getInt("totalExecutions") ?? 0;
      totalExecutions++;
      sharedPreference.setInt(
        "totalExecutions",
        totalExecutions,
      );
      developer.log("Total executions: $totalExecutions");
    } catch (err) {
      developer.log(
        err.toString(),
      );
      throw Exception(err);
    }

    return Future.value(true);
  });
}

Future<FlutterLocalNotificationsPlugin> initNotifications() async {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('favicon_alpha');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse nr) {
      developer.log("Recieved a notification response");
    },
  );

  return flutterLocalNotificationsPlugin;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(
    callbackDispatcher, // The top level function, aka callbackDispatcher
    // If enabled it will post a notification whenever the task is running. Handy for debugging tasks
    isInDebugMode: false,
  );
  Workmanager().registerPeriodicTask(
    "periodic-task-identifier",
    "updateChecker",
    existingWorkPolicy: ExistingWorkPolicy.replace,
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresBatteryNotLow: true,
      requiresCharging: false,
      requiresDeviceIdle: false,
      requiresStorageNotLow: true,
    ),
    // tag: "my-tag",
    // backoffPolicy: BackoffPolicy.exponential,
    // frequency: Duration(minutes: 15),
  );

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      await initNotifications();
  flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestPermission();

  runApp(const MyApp());
}

// void onDidReceiveNotificationResponse(
//     NotificationResponse notificationResponse) async {
//   final String? payload = notificationResponse.payload;
//   if (notificationResponse.payload != null) {
//     debugPrint('notification payload: $payload');
//   }
//   await Navigator.push(
//     context,
//     MaterialPageRoute<void>(builder: (context) => SecondScreen(payload)),
//   );
// }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LFGSS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromRGBO(30, 114, 196, 1.0),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const HomePage(title: 'LFGSS'),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      // appBar: AppBar(
      //   // Here we take the value from the MyHomePage object that was created by
      //   // the App.build method, and use it to set our appbar title.
      //   title: Text(unescape.convert(widget.microcosm.title)),
      // ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
            // backgroundColor: Colors.black,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.newspaper),
            label: 'Today',
            // backgroundColor: Colors.black,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_outlined),
            label: 'Following',
            // backgroundColor: Colors.black,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum),
            label: 'Huddles',
            // backgroundColor: Colors.black,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'You',
            // backgroundColor: Colors.black,
          ),
        ],
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue[400],
        onTap: (value) {
          setState(() {
            _currentIndex = value;
          });
        },
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: <Widget>[
          FutureMicrocosmScreen(microcosm: Microcosm.root()),
          FutureSearchScreen(
            search: Search.search(
              searchParameters: SearchParameters(
                query: "",
                since: -1,
                type: {'conversation', 'event', 'profile', 'huddle'},
              ),
            ),
          ),
          FutureUpdatesScreen(updates: Updates.root()),
          FutureHuddlesScreen(huddles: Huddles.root()),
          ProfileScreen(profile: Profile.getProfile()),
        ],
      ),
    );
  }
}
