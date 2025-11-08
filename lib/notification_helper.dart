import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon'); // default icon

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Request permissions for Android
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Request permissions for iOS
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> showEmiReminder({
    required int id,
    required String loanName,
    required double amount,
    required int daysLeft,
  }) async {
    String title = 'EMI Reminder';
    String body;

    if (daysLeft == 0) {
      body = 'Your EMI for $loanName (Amount: $amount) is due today.';
    } else if (daysLeft == 1) {
      body = 'Your EMI for $loanName (Amount: $amount) is due tomorrow.';
    } else {
      body =
          'Your EMI for $loanName (Amount: $amount) is due in $daysLeft days.';
    }

    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'emi_reminder_channel',
        'EMI Reminders',
        channelDescription: 'Channel for EMI payment reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }

  Future<void> showBigPictureNotification({
    required int id,
    required String loanName,
    required double amount,
    required String imagePath,
  }) async {
    // Style information for showing a big picture.
    final BigPictureStyleInformation bigPictureStyleInformation =
        BigPictureStyleInformation(
      FilePathAndroidBitmap(imagePath),
      // The content title when the notification is expanded.
      contentTitle: 'EMI Reminder: $loanName',
      // The summary text when the notification is expanded.
      summaryText: 'Your EMI of $amount is due soon.',
      // Hide the icon when the notification is expanded
      hideExpandedLargeIcon: true,
    );

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'big_picture_emi_reminders', // Channel ID
      'Big Picture EMI Reminders', // Channel Name
      channelDescription:
          'Channel for showing EMI reminders with a card image.',
      styleInformation: bigPictureStyleInformation,
      importance: Importance.max,
      priority: Priority.high,
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
        id, 'EMI Reminder', 'Due for $loanName', platformChannelSpecifics);
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> showTestNotification() async {
    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'test_channel',
        'Test Notifications',
        channelDescription: 'Channel for testing notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await flutterLocalNotificationsPlugin.show(
      999, // A static ID for the test notification
      'Test Notification',
      'If you see this, notifications are working!',
      notificationDetails,
    );
  }
}
