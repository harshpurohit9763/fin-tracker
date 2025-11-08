import 'package:flutter/material.dart';
import 'package:personal_finance/db_helper.dart';
import 'package:personal_finance/emi_repo.dart';
import 'package:personal_finance/main.dart';
import 'package:personal_finance/notification_helper.dart';
import 'package:personal_finance/shared_preferences_provider.dart';
import 'package:personal_finance/upcoming_emi_card.dart';
import 'package:personal_finance/widget_to_image_renderer.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';

const simpleTaskKey = "exp_track_simple_task";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    await DatabaseHelper.instance.database;
    // We need to initialize notifications before using them
    await NotificationService().init();
    switch (task) {
      case simpleTaskKey:
        await checkEmisAndSendReminders();
        break;
    }
    return Future.value(true);
  });
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
