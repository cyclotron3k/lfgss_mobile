import 'dart:developer' show log;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'models/update.dart';
import 'models/update_type.dart';
import 'models/updates.dart';
import 'services/microcosm_client.dart';

const _notificationTaskUniqueName = "periodic-task-identifier";
const _notificationTaskName = "updateChecker";
const notificationPreferenceKeys = [
  "notifyNewComments",
  "notifyNewConversations",
  "notifyReplies",
  "notifyMentions",
  "notifyHuddles",
];

bool notificationsEnabled(SharedPreferences prefs) {
  return notificationPreferenceKeys.any((key) => prefs.getBool(key) ?? true);
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    int totalExecutions;
    final sp = await SharedPreferences.getInstance(); // Initialize dependency

    try {
      if (!notificationsEnabled(sp)) {
        await cancelNotificationTask();
        log("Notifications disabled");
        return true;
      }

      final client = MicrocosmClient();
      await client.updateAccessToken();
      if (!client.loggedIn) {
        log("Not logged in");
        await cancelNotificationTask();
        return true;
      }

      Updates updates = await Updates.root(pageSize: 25);
      List<Update> notifications = await updates.getNewUpdates();
      log("New updates: ${notifications.length}");

      final bool notifyNewComments = sp.getBool("notifyNewComments") ?? true;
      final bool notifyNewConversations =
          sp.getBool("notifyNewConversations") ?? true;
      final bool notifyReplies = sp.getBool("notifyReplies") ?? true;
      final bool notifyMentions = sp.getBool("notifyMentions") ?? true;
      final bool notifyHuddles = sp.getBool("notifyHuddles") ?? true;

      const generalNotificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'lfgss_updates',
          'Updates',
          channelDescription: 'Updates from LFGSS',
          importance: Importance.max,
          priority: Priority.high,
        ),
      );

      const importantNotificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'lfgss_replies',
          'Replies & Mentions',
          channelDescription: 'Replies and Mentions',
          icon: 'ic_stat_lfgss_notification_hed3',
          importance: Importance.max,
          priority: Priority.high,
        ),
      );

      final flutterLocalNotificationsPlugin = await initNotifications(null);

      for (final update in notifications) {
        final bool send = switch (update.updateType) {
          UpdateType.event_reminder => false, // TODO
          UpdateType.mentioned => notifyMentions,
          UpdateType.new_comment => notifyNewComments,
          UpdateType.new_comment_in_huddle => notifyHuddles,
          UpdateType.new_attendee => false, // TODO
          UpdateType.new_item => notifyNewConversations,
          UpdateType.new_vote => false, // TODO
          UpdateType.new_user => false, // TODO
          UpdateType.reply_to_comment => notifyReplies,
        };

        if (!send) continue;

        final important = update.updateType == UpdateType.reply_to_comment ||
            update.updateType == UpdateType.mentioned ||
            update.updateType == UpdateType.new_comment_in_huddle;

        await flutterLocalNotificationsPlugin.show(
          id: update.topicId,
          title: update.title,
          body: update.body,
          notificationDetails: important
              ? importantNotificationDetails
              : generalNotificationDetails,
          payload: update.payload,
        );
      }

      totalExecutions = sp.getInt("totalExecutions") ?? 0;
      totalExecutions++;
      sp.setInt(
        "totalExecutions",
        totalExecutions,
      );
      log("Total executions: $totalExecutions");
    } catch (err) {
      log(err.toString());
      throw Exception(err);
    }

    return true;
  });
}

Future<FlutterLocalNotificationsPlugin> initNotifications(
  Function(NotificationResponse)? callback,
) async {
  final plugin = FlutterLocalNotificationsPlugin();

  await plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_lfgss_notification'),
    ),
    onDidReceiveNotificationResponse: callback,
  );

  return plugin;
}

Future<void> initTasks() async {
  await Workmanager().initialize(
    callbackDispatcher, // The top level function, aka callbackDispatcher
  );

  final prefs = await SharedPreferences.getInstance();
  await syncNotificationTask(prefs, requestPermission: true);
}

Future<void> syncNotificationTask(
  SharedPreferences prefs, {
  bool requestPermission = false,
}) async {
  final client = MicrocosmClient();
  await client.updateAccessToken();

  if (client.loggedIn && notificationsEnabled(prefs)) {
    await registerNotificationTask();

    if (requestPermission) {
      final plugin = await initNotifications(null);
      await plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  } else {
    await cancelNotificationTask();
  }
}

Future<void> registerNotificationTask() async {
  await Workmanager().registerPeriodicTask(
    _notificationTaskUniqueName,
    _notificationTaskName,
    existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresBatteryNotLow: true,
      requiresCharging: false,
      requiresDeviceIdle: false,
      requiresStorageNotLow: false,
    ),
    // tag: "my-tag",
    // backoffPolicy: BackoffPolicy.exponential,
    // frequency: Duration(minutes: 15),
  );
}

Future<void> cancelNotificationTask() async {
  await Workmanager().cancelByUniqueName(_notificationTaskUniqueName);
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
