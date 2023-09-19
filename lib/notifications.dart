import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'models/update.dart';
import 'models/updates.dart';
import 'services/microcosm_client.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    int totalExecutions;
    final sharedPreference =
        await SharedPreferences.getInstance(); // Initialize dependency

    try {
      await MicrocosmClient().updateAccessToken();
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
            await initNotifications(null);

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

Future<FlutterLocalNotificationsPlugin> initNotifications(
    Function(NotificationResponse)? callback) async {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('favicon_alpha');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: callback,
  );

  return flutterLocalNotificationsPlugin;
}

Future<void> initTasks() async {
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
      await initNotifications(null);
  flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestPermission();
}

  // // DELETE START
  // const AndroidNotificationDetails androidNotificationDetails =
  //     AndroidNotificationDetails(
  //   'lfgss_updates',
  //   'LFGSS Updates',
  //   channelDescription: 'Updates from LFGSS',
  //   importance: Importance.max,
  //   priority: Priority.high,
  //   ticker: 'ticker',
  // );

  // const NotificationDetails notificationDetails = NotificationDetails(
  //   android: androidNotificationDetails,
  // );

  // flutterLocalNotificationsPlugin.show(
  //   12345,
  //   "Test Notification",
  //   "Body text",
  //   notificationDetails,
  //   payload: "253639",
  // );
  // // DELETE END
