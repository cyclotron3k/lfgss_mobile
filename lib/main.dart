import 'package:flutter/material.dart';
import 'package:flutter_native_timezone_updated_gradle/flutter_native_timezone.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart';
import 'package:timezone/timezone.dart';

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

  final String timeZone = await FlutterNativeTimezone.getLocalTimezone();
  setLocalLocation(getLocation(timeZone));

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
          ).copyWith(
            inversePrimary: const Color.fromARGB(255, 209, 112, 1),
            onSurfaceVariant: Colors.grey.shade600,
          ),
          // textTheme: TextTheme(),
        );

        var darkTheme = ThemeData(
          dialogTheme: DialogTheme(backgroundColor: Colors.grey[850]),
          colorScheme: ColorScheme.fromSeed(
            brightness: Brightness.dark,
            seedColor: const Color.fromARGB(255, 0x1e, 0x72, 0xc4),
          ).copyWith(
            primary: const Color.fromARGB(255, 62, 166, 240),
            inversePrimary: const Color.fromARGB(255, 236, 161, 20),
            onSurfaceVariant: Colors.grey.shade500,
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
