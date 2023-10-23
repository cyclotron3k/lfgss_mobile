import 'dart:convert';
import 'dart:developer' show log;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/conversation.dart';
import '../../models/event.dart';
import '../../models/full_profile.dart';
import '../../models/huddle.dart';
import '../../models/huddles.dart';
import '../../models/microcosm.dart';
import '../../models/search.dart';
import '../../models/updates.dart';
import '../../notifications.dart';
import '../../services/microcosm_client.dart';
import '../adaptable_form.dart';
import '../login_to_see.dart';
import 'future_huddles_screen.dart';
import 'future_microcosm_screen.dart';
import 'future_screen.dart';
import 'future_search_results_screen.dart';
import 'future_updates_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<Widget> _tabs = [];
  int _currentIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<FullProfile>? profile;
  String? profileName;
  String? profileAvatar;
  String? profileEmail;

  // late StreamSubscription _intentDataStreamSubscription;
  // late List<SharedMediaFile> _sharedFiles;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _initProfile();
    _initTabs();
    if (MicrocosmClient().loggedIn) _currentIndex = 2;

    _runWhileAppIsTerminated();

    // For sharing images coming from outside the app while the app is in the memory
    ReceiveSharingIntent.getMediaStream().listen(
      (List<SharedMediaFile> value) {
        if (value.isEmpty) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            fullscreenDialog: true,
            maintainState: true,
            builder: (context) => AdaptableForm(
              initialAttachments: value,
              onPostSuccess: () {},
            ),
          ),
        );
      },
      onError: (err) {
        log("getIntentDataStream error: $err");
      },
    );

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialMedia().then(
      (List<SharedMediaFile> value) {
        if (value.isEmpty) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            fullscreenDialog: true,
            maintainState: true,
            builder: (context) => AdaptableForm(
              initialAttachments: value,
              onPostSuccess: () {},
            ),
          ),
        );
      },
      onError: (err) {
        log("getIntentDataStream error: $err");
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _refresh() {
    _following?.then((value) => value.resetChildren());
    _huddles?.then((value) => value.resetChildren());
    _today.then((value) => value.resetChildren());
  }

  Future<Updates>? _following;
  Future<Huddles>? _huddles;
  final Future<Search> _today = Search.today();

  void _initTabs() {
    if (MicrocosmClient().loggedIn) {
      _following = Updates.root();
      _huddles = Huddles.root();
    }

    _tabs = <Widget>[
      FutureMicrocosmScreen(microcosm: Microcosm.root()),
      FutureSearchResultsScreen(
        search: _today,
        title: "Today",
        showSummary: false,
      ),
      MicrocosmClient().loggedIn
          ? FutureUpdatesScreen(updates: _following!)
          : const LoginToSee(
              what: "your updates",
              icon: Icon(Icons.bookmark_border),
            ),
      MicrocosmClient().loggedIn
          ? FutureHuddlesScreen(huddles: _huddles!)
          : const LoginToSee(
              what: "Huddles",
              icon: Icon(Icons.email_outlined),
            ),
      // ProfileScreen(profile: Profile.getProfile()),
    ];
  }

  void _initProfile() {
    if (MicrocosmClient().loggedIn) {
      profile = FullProfile.getProfile();
      profile!.then((FullProfile p) {
        setState(() {
          profileName = p.profileName;
          profileAvatar = p.avatar;
          profileEmail = p.email;
        });
      });
    } else {
      profile = null;
      profileName = null;
      profileAvatar = null;
      profileEmail = null;
    }
  }

  void _handleNotification(NotificationResponse nr) {
    String payload = nr.payload ?? "";
    log("Payload: $payload");

    if (payload == "") return;

    try {
      final dynamic parsed = jsonDecode(payload);

      Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          maintainState: true,
          builder: (context) => switch (parsed["goto"] as String) {
            "conversation" => FutureScreen(
                item: Conversation.getById(
                  parsed["id"] as int,
                ),
              ),
            "event" => FutureScreen(
                item: Event.getById(
                  parsed["id"] as int,
                ),
              ),
            "huddle" => FutureScreen(
                item: Huddle.getById(
                  parsed["id"] as int,
                ),
              ),
            _ => Placeholder(child: Text("Not implemented: ${parsed["goto"]}")),
          },
        ),
      );
    } catch (e) {
      log("Notification error: ${e.toString()}");
      return;
    }
  }

  void _runWhileAppIsTerminated() async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        await initNotifications(_handleNotification);
    var details =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

    if (details == null) return;

    if (!context.mounted) return;

    if (details.didNotificationLaunchApp) {
      if (details.notificationResponse?.payload == null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            fullscreenDialog: true,
            maintainState: true,
            builder: (context) => FutureUpdatesScreen(
              updates: Updates.root(),
            ),
          ),
        );
      } else {
        _handleNotification(details.notificationResponse!);
      }
    } else {
      log("App start not triggered by notification");
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
            UserAccountsDrawerHeader(
              accountName: Text(profileName ?? "LFGSS"),
              accountEmail: Text(profileEmail ?? ""),
              currentAccountPicture: CachedNetworkImage(
                imageUrl: profileAvatar ??
                    "https://lfgss.microcosm.app/api/v1/files/3967bb6b279adca3d4b8a174c1021f3d642c32fc.png",
              ),
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.jpg'),
                  fit: BoxFit.fill,
                ),
              ),
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
              leading: Icon(
                MicrocosmClient().loggedIn ? Icons.logout : Icons.login,
              ),
              title: Text(MicrocosmClient().loggedIn ? 'Logout' : 'Login'),
              onTap: () async {
                if (MicrocosmClient().loggedIn) {
                  await MicrocosmClient().logout();
                  _initProfile();
                  _initTabs();
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
                  _initProfile();
                  _initTabs();
                  setState(() {});
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text("About"),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationIcon: const CircleAvatar(
                    backgroundImage: AssetImage(
                      'assets/launcher_icon/background.png',
                    ),
                    foregroundImage: AssetImage(
                      'assets/launcher_icon/foreground.png',
                    ),
                  ),
                  applicationVersion: '1.0.12',
                  children: [
                    const Text("Built by me, Aidan Samuel"),
                    const Text("aka @cyclotron3k"),
                    const SizedBox(height: 10.0),
                    Text.rich(
                      TextSpan(
                        text: "This is an open-source project. ",
                        children: [
                          const TextSpan(
                            text:
                                "Build it yourself, contribute code or report issues on ",
                          ),
                          TextSpan(
                            text: "GitHub",
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                launchUrl(
                                  Uri.parse(
                                    "https://github.com/cyclotron3k/lfgss_mobile",
                                  ),
                                  mode: LaunchMode.externalApplication,
                                );
                              },
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
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
            setState(() => _currentIndex = value);
          }
        },
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
    );
  }
}
