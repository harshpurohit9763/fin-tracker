import 'package:flutter/material.dart';
import 'package:personal_finance/db_helper.dart';
import 'package:personal_finance/emi_repo.dart';
import 'package:personal_finance/notification_helper.dart';
import 'package:workmanager/workmanager.dart';

const simpleTaskKey = "exp_track_simple_task";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    await DatabaseHelper.instance.database;
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
  final allActiveEmis = await emiRepo.getAllActiveEmis();

  // Use a date-only representation for today to avoid time-based issues
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  for (final emi in allActiveEmis) {
    final dueDate = DateTime(
        emi.nextDueDate.year, emi.nextDueDate.month, emi.nextDueDate.day);
    final differenceInDays = dueDate.difference(today).inDays;

    // Reminder 2 days before
    if (differenceInDays == 2) {
      await notificationService.showEmiReminder(
          id: emi.id! + 20000, // Unique ID for 2-day reminder
          loanName: emi.loanName,
          amount: emi.monthlyEmiAmount,
          daysLeft: 2);
    }
    // Reminder 1 day before
    else if (differenceInDays == 1) {
      await notificationService.showEmiReminder(
          id: emi.id! + 10000, // Unique ID for 1-day reminder
          loanName: emi.loanName,
          amount: emi.monthlyEmiAmount,
          daysLeft: 1);
    }
    // Reminder on the due date
    else if (differenceInDays == 0) {
      await notificationService.showEmiReminder(
          id: emi.id!, // Base ID for due date reminder
          loanName: emi.loanName,
          amount: emi.monthlyEmiAmount,
          daysLeft: 0);
    }
  }
}
