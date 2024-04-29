import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart';

import 'models/full_profile.dart';
import 'models/user_provider.dart';
import 'notifications.dart';
import 'services/microcosm_client.dart';
import 'services/observer_utils.dart';
import 'services/settings.dart';
import 'widgets/screens/home_screen.dart';

typedef Json = Map<String, dynamic>;

void main() async {
  initializeTimeZones();
  WidgetsFlutterBinding.ensureInitialized();
  initTasks();

  var settings = Settings(
    await SharedPreferences.getInstance(),
  );

  var userProvider = UserProvider();
  await MicrocosmClient().updateAccessToken();
  if (MicrocosmClient().loggedIn) {
    FullProfile.getProfile().then(
      (value) => userProvider.user = value,
    );
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => settings),
        ChangeNotifierProvider(create: (context) => userProvider),
      ],
      child: const LfgssMobile(),
    ),
  );
}

class LfgssMobile extends StatelessWidget {
  const LfgssMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<Settings>(
      builder: (context, settings, child) {
        var lightTheme = ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 77, 134, 219),
          ),
          // textTheme: TextTheme(),
        );

        var darkTheme = ThemeData(
          colorScheme: ColorScheme.fromSeed(
            brightness: Brightness.dark,
            seedColor: const Color.fromARGB(255, 0x1e, 0x72, 0xc4),
          ).copyWith(
            primary: const Color.fromARGB(255, 62, 166, 240),
            inversePrimary: Color.fromARGB(255, 236, 161, 20),
          ),
        );

        String darkMode = settings.getString("darkMode") ?? "system";

        if (darkMode == "light") {
          darkTheme = lightTheme;
        } else if (darkMode == "dark") {
          lightTheme = darkTheme;
        }

        return MaterialApp(
          title: 'LFGSS',
          theme: lightTheme,
          darkTheme: darkTheme,
          home: const HomeScreen(title: 'LFGSS'),
          navigatorObservers: [ObserverUtils.routeObserver],
        );
      },
    );
  }
}
