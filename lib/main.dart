import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'api/microcosm_client.dart';
import 'models/conversation.dart';
import 'models/huddles.dart';
import 'models/microcosm.dart';
import 'models/search.dart';
import 'models/updates.dart';
import 'notifications.dart';
import 'widgets/future_conversation_screen.dart';
import 'widgets/future_huddles_screen.dart';
import 'widgets/future_microcosm_screen.dart';
import 'widgets/future_search_screen.dart';
import 'widgets/future_updates_screen.dart';
import 'widgets/login_screen.dart';
import 'widgets/login_to_see.dart';
import 'widgets/settings_screen.dart';

typedef Json = Map<String, dynamic>;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initTasks();

  await MicrocosmClient().updateAccessToken();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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

  void _handleNotification(NotificationResponse nr) {
    String payload = nr.payload ?? "0";
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

  void _runWhileAppIsTerminated() async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        await initNotifications(_handleNotification);
    var details =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

    if (details == null) return;

    if (details.didNotificationLaunchApp) {
      if (details.notificationResponse?.payload == null) return;
      _handleNotification(details.notificationResponse!);
    } else {
      developer.log("Ignored payload");
    }
  }

  void _toggleDrawer() {
    var scaffold = _scaffoldKey.currentState;
    if (scaffold == null) {
      return;
    }
    if (scaffold.isEndDrawerOpen) {
      scaffold.closeEndDrawer();
    } else {
      scaffold.openEndDrawer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: Drawer(
        child: ListView(
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
                _toggleDrawer();
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
                _toggleDrawer();
                // Update the state of the app.
                // ...
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(MicrocosmClient().loggedIn ? 'Logout' : 'Login'),
              onTap: () async {
                if (MicrocosmClient().loggedIn) {
                  await MicrocosmClient().logout();
                  setState(() {});
                } else {
                  _toggleDrawer();
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      maintainState: false,
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                  setState(() {});
                }
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        showSelectedLabels: true,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
            // backgroundColor: Colors.black,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.newspaper_outlined),
            activeIcon: Icon(Icons.newspaper),
            label: 'Today',
            // backgroundColor: Colors.black,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border),
            activeIcon: Icon(Icons.bookmark),
            label: 'Following',
            // backgroundColor: Colors.black,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.email_outlined),
            activeIcon: Icon(Icons.email),
            label: 'Huddles',
            // backgroundColor: Colors.black,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'Menu',
            // backgroundColor: Colors.black,
          ),
        ],
        currentIndex: _currentIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: (value) {
          if (value == 4) {
            _toggleDrawer();
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
          FutureSearchScreen(search: Search.today()),
          MicrocosmClient().loggedIn
              ? FutureUpdatesScreen(updates: Updates.root())
              : const LoginToSee(
                  what: "your updates",
                  icon: Icon(Icons.bookmark_border),
                ),
          MicrocosmClient().loggedIn
              ? FutureHuddlesScreen(huddles: Huddles.root())
              : const LoginToSee(
                  what: "Huddles",
                  icon: Icon(Icons.email_outlined),
                ),
          // ProfileScreen(profile: Profile.getProfile()),
        ],
      ),
    );
  }
}
