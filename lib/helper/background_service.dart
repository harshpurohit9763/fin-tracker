import 'package:flutter/material.dart';
import 'package:personal_finance/db/db_helper.dart';
import 'package:personal_finance/helper/emi_repo.dart';
import 'package:personal_finance/helper/notification_helper.dart';
import 'package:personal_finance/widgets/upcoming_emi_card.dart';
import 'package:personal_finance/widgets/widget_to_image_renderer.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:personal_finance/helper/data_backup_service.dart';

const emiCheckTaskKey = "exp_track_emi_check_task";
const backupTaskKey = "exp_track_backup_task";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    await DatabaseHelper.instance.database;
    await NotificationService().init();

    switch (task) {
      case emiCheckTaskKey:
        return await emiCallbackDispatcher(task, inputData);
      case backupTaskKey:
        return await backupCallbackDispatcher(task, inputData);
      default:
        return Future.value(true);
    }
  });
}

Future<bool> emiCallbackDispatcher(
    String task, Map<String, dynamic>? inputData) async {
  await checkEmisAndSendReminders();
  return Future.value(true);
}

Future<bool> backupCallbackDispatcher(
    String task, Map<String, dynamic>? inputData) async {
  final prefs = await SharedPreferences.getInstance();
  final database = await DatabaseHelper.instance.database;
  final backupService = DataBackupService(prefs, database);
  try {
    await backupService.exportData();
    return Future.value(true);
  } catch (e) {
    return Future.value(false);
  }
}

Future<void> checkEmisAndSendReminders() async {
  final emiRepo = EmiRepository();
  final notificationService = NotificationService();
  final prefs = await SharedPreferences.getInstance();

  // Load user preferences needed for the card
  final currency = prefs.getString('currency') ?? 'USD';
  final userName = prefs.getString('userName') ?? 'User';
  final accentColor =
      Color(prefs.getInt('accentColor') ?? Colors.deepPurple.value);

  final allActiveEmis = await emiRepo.getAllActiveEmis();

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  for (final emi in allActiveEmis) {
    final dueDate = DateTime(
        emi.nextDueDate.year, emi.nextDueDate.month, emi.nextDueDate.day);
    final differenceInDays = dueDate.difference(today).inDays;

    // Send reminder on due date, 1 day before, and 2 days before
    if (differenceInDays >= 0 && differenceInDays <= 2) {
      // Create a theme for the off-screen widget to ensure it looks correct
      final cardTheme = ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentColor,
          brightness: Brightness.dark, // Use dark theme for better contrast
        ),
        useMaterial3: true,
      );

      // The widget to be rendered
      final emiCardWidget = Theme(
        data: cardTheme,
        child: UpcomingEmiCard(
          emi: emi,
          currency: currency,
          userName: userName,
          onProfileTap: () {}, // No-op for notifications
        ),
      );

      // Render the widget to an image file
      final imagePath =
          await WidgetToImageRenderer.renderOffScreen(emiCardWidget);

      // Use a unique ID for each day's notification to avoid overwriting
      final notificationId = emi.id! + (differenceInDays * 10000);

      await notificationService.showBigPictureNotification(
        id: notificationId,
        loanName: emi.loanName,
        amount: emi.monthlyEmiAmount,
        imagePath: imagePath,
      );
    }
  }
}
