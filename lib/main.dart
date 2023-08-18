import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lfgss_mobile/widgets/future_conversation_screen.dart';
import 'package:lfgss_mobile/widgets/future_microcosm_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'dart:developer' as developer;

import 'models/conversation.dart';
import 'models/huddles.dart';
import 'models/microcosm.dart';
import 'models/profile.dart';
import 'models/search.dart';
import 'models/search_parameters.dart';
import 'models/update.dart';
import 'models/updates.dart';
import 'widgets/future_huddles_screen.dart';
import 'widgets/future_search_screen.dart';
import 'widgets/future_updates_screen.dart';
import 'widgets/profile_screen.dart';
import 'widgets/settings_screen.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    int totalExecutions;
    final sharedPreference =
        await SharedPreferences.getInstance(); // Initialize dependency

    try {
      Updates updates = await Updates.root();
      List<Update> notifications = await updates.getNewUpdates();
      developer.log("New updates: ${notifications.length}");

      for (var update in notifications) {
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
          update.topicId,
          update.title,
          update.body,
          notificationDetails,
          payload: update.conversationId,
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
          seedColor: const Color.fromARGB(255, 77, 134, 219),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color.fromARGB(255, 60, 41, 230),
        ),
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
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _runWhileAppIsTerminated();
  }

  void _runWhileAppIsTerminated() async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        await initNotifications();
    var details =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

    if (details == null) return;

    if (details.didNotificationLaunchApp) {
      if (details.notificationResponse?.payload == null) return;
      String payload = details.notificationResponse?.payload ?? "0";

      developer.log("Payload: $payload");

      Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          maintainState: true,
          builder: (context) => FutureConversationScreen(
            conversation: Conversation.getById(
              int.parse(payload),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      key: _scaffoldKey,
      // appBar: AppBar(
      //   // Here we take the value from the MyHomePage object that was created by
      //   // the App.build method, and use it to set our appbar title.
      //   title: Text(unescape.convert(widget.microcosm.title)),
      // ),
      endDrawer: Drawer(
        // Add a ListView to the drawer. This ensures the user can scroll
        // through the options in the drawer if there isn't enough vertical
        // space to fit everything.
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: const Text('LFGSS'),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    maintainState: true,
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: const Text('Bookmarks'),
              onTap: () {
                // Update the state of the app.
                // ...
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                // Update the state of the app.
                // ...
              },
            ),
          ],
        ),
      ),

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
            icon: Icon(Icons.menu),
            label: '',
            // backgroundColor: Colors.black,
          ),
        ],
        currentIndex: _currentIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: (value) {
          if (value == 4) {
            // var scaffold = Scaffold.of(context);
            var scaffold = _scaffoldKey.currentState;
            if (scaffold == null) {
              return;
            }
            if (scaffold.isEndDrawerOpen) {
              scaffold.closeEndDrawer();
            } else {
              scaffold.openEndDrawer();
            }
          } else {
            setState(() {
              _currentIndex = value;
            });
          }
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
