import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:offline_expense_tracker/app_formater.dart';
import 'package:offline_expense_tracker/asset_model.dart';
import 'package:offline_expense_tracker/budget_provider.dart';
import 'package:offline_expense_tracker/expense_model.dart';
import 'package:offline_expense_tracker/insights_provider.dart';
import 'package:offline_expense_tracker/subscription_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportExporter {
  // --- Color Palette ---
  static const PdfColor deepBlue = PdfColor.fromInt(0xFF003366);
  static const PdfColor mustardYellow = PdfColor.fromInt(0xFFFFDB58);
  static const PdfColor lightGrey = PdfColor.fromInt(0xFFF0F0F0);
  static const PdfColor darkGrey = PdfColor.fromInt(0xFF333333);

  static Future<void> generateAndShareReport({
    required DateTimeRange dateRange,
    required String userName,
    required String currency,
    required List<Expense> expenses,
    required SpendingBreakdown spendingBreakdown,
    required List<Asset> assets,
    required List<Subscription> subscriptions,
    required Map<String, double> budgetData,
  }) async {
    final doc = pw.Document();

    // Use try-catch for font loading as it requires internet
    pw.Font font;
    pw.Font boldFont;
    try {
      font = await PdfGoogleFonts.openSansRegular();
      boldFont = await PdfGoogleFonts.openSansBold();
    } catch (e) {
      font = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
    }

    final pw.ThemeData theme = pw.ThemeData.withFont(
      base: font,
      bold: boldFont,
    );

    // --- Reusable Widgets & Styles ---
    pw.Widget sectionHeader(String title) {
      return pw.Container(
        decoration: const pw.BoxDecoration(
          color: deepBlue,
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(
          title,
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
            fontSize: 16,
          ),
        ),
      );
    }

    pw.Widget placeholderText() {
      return pw.Text(
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
        'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. '
        'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. '
        'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.',
        textAlign: pw.TextAlign.justify,
      );
    }

    // --- Page Definitions ---

    // 1. Cover Page
    doc.addPage(
      pw.Page(
        theme: theme,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'Financial Report',
                  style: pw.TextStyle(
                      fontSize: 40,
                      fontWeight: pw.FontWeight.bold,
                      color: deepBlue),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Prepared for: $userName',
                  style: const pw.TextStyle(fontSize: 20),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Period: ${AppFormatters.formatDate(dateRange.start)} - ${AppFormatters.formatDate(dateRange.end)}',
                  style: const pw.TextStyle(fontSize: 16, color: darkGrey),
                ),
              ],
            ),
          );
        },
      ),
    );

    // 2. Highlights & Review of Operations
    doc.addPage(
      pw.MultiPage(
        theme: theme,
        header: (context) => pw.Header(
            level: 0,
            child: pw.Text('Report Highlights',
                style: pw.TextStyle(
                    fontSize: 20, fontWeight: pw.FontWeight.bold))),
        build: (pw.Context context) {
          final totalExpenses =
              spendingBreakdown.needs + spendingBreakdown.wants;
          final netFlow = spendingBreakdown.investments - totalExpenses;

          return [
            sectionHeader('Review of Operations'),
            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Expenses (Needs + Wants):'),
                pw.Text(AppFormatters.formatCurrency(totalExpenses, currency),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Savings (Investments):'),
                pw.Text(
                    AppFormatters.formatCurrency(
                        spendingBreakdown.investments, currency),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.Divider(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Net Cash Flow:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(AppFormatters.formatCurrency(netFlow, currency),
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: netFlow >= 0 ? PdfColors.green : PdfColors.red)),
              ],
            ),
            pw.SizedBox(height: 24),

            // Budget Summary
            sectionHeader('Budget Performance'),
            pw.SizedBox(height: 16),
            _buildBudgetSummary(budgetData, currency),
            pw.SizedBox(height: 24),

            // Asset Summary
            sectionHeader('Asset Summary'),
            pw.SizedBox(height: 16),
            _buildAssetTable(assets, currency),
            pw.SizedBox(height: 24),

            // Recurring Costs
            sectionHeader('Recurring Costs (Monthly)'),
            pw.SizedBox(height: 16),
            _buildSubscriptionTable(subscriptions, currency),
          ];
        },
      ),
    );

    // 3. Director's Report & Social Matters (Placeholders)
    doc.addPage(
      pw.MultiPage(
        theme: theme,
        header: (context) => pw.Header(
            level: 0,
            child: pw.Text("Management's Discussion",
                style: pw.TextStyle(
                    fontSize: 20, fontWeight: pw.FontWeight.bold))),
        build: (pw.Context context) {
          return [
            sectionHeader("Director's Report"),
            pw.SizedBox(height: 16),
            placeholderText(),
            pw.SizedBox(height: 24),
            sectionHeader('Social & Environmental Matters'),
            pw.SizedBox(height: 16),
            placeholderText(),
            pw.SizedBox(height: 24),
            sectionHeader("Statement of Directors' Responsibilities"),
            pw.SizedBox(height: 16),
            placeholderText(),
          ];
        },
      ),
    );

    // 4. Transaction List
    doc.addPage(
      pw.MultiPage(
        theme: theme,
        header: (context) => pw.Header(
            level: 0,
            child: pw.Text('Detailed Transactions',
                style: pw.TextStyle(
                    fontSize: 20, fontWeight: pw.FontWeight.bold))),
        build: (pw.Context context) {
          return [_buildTransactionTable(expenses, currency)];
        },
      ),
    );

    // --- Share the document ---
    await Printing.sharePdf(
        bytes: await doc.save(), filename: 'financial-report.pdf');
  }

  // --- Helper methods for building tables ---

  static pw.Widget _buildBudgetSummary(
      Map<String, double> budgetData, String currency) {
    final spent = budgetData['spent'] ?? 0.0;
    final total = budgetData['total'] ?? 0.0;

    if (total == 0) {
      return pw.Text('No budgets set for this period.');
    }

    final percentage = total > 0 ? (spent / total).clamp(0.0, 1.0) : 0.0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
            'Spent ${AppFormatters.formatCurrency(spent, currency)} of ${AppFormatters.formatCurrency(total, currency)}'),
        pw.SizedBox(height: 8),
        pw.ClipRRect(
          horizontalRadius: 5,
          verticalRadius: 5,
          child: pw.LinearProgressIndicator(
            value: percentage,
            backgroundColor: lightGrey,
            valueColor: mustardYellow,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildAssetTable(List<Asset> assets, String currency) {
    if (assets.isEmpty) return pw.Text('No assets recorded.');

    final headers = ['Asset Name', 'Value'];
    final data = assets
        .map((asset) =>
            [asset.name, AppFormatters.formatCurrency(asset.value, currency)])
        .toList();

    final total = assets.fold<double>(0.0, (sum, asset) => sum + asset.value);

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(color: lightGrey),
      headerStyle:
          pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: deepBlue),
      cellStyle: const pw.TextStyle(),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
      },
      // footerBuilder: (context) {
      //   return pw.Text(
      //     'Total Assets: ${AppFormatters.formatCurrency(total, currency)}',
      //     style: pw.TextStyle(
      //       fontWeight: pw.FontWeight.bold,
      //     ),
      //   );
      // },
    );
  }

  static pw.Widget _buildSubscriptionTable(
      List<Subscription> subs, String currency) {
    if (subs.isEmpty) return pw.Text('No recurring costs recorded.');

    final headers = ['Service', 'Monthly Cost'];
    final data = subs
        .map((sub) =>
            [sub.name, AppFormatters.formatCurrency(sub.amount, currency)])
        .toList();

    final total = subs.fold<double>(0.0, (sum, sub) => sum + sub.amount);

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(color: lightGrey),
      headerStyle:
          pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: deepBlue),
      cellStyle: const pw.TextStyle(),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
      },
      // footerBuilder: (context) {
      //   return pw.Text(
      //     'Total Monthly Cost: ${AppFormatters.formatCurrency(total, currency)}',
      //     style: pw.TextStyle(
      //       fontWeight: pw.FontWeight.bold,
      //     ),
      //   );
      // },
    );
  }

  static pw.Widget _buildTransactionTable(
      List<Expense> expenses, String currency) {
    if (expenses.isEmpty) return pw.Text('No transactions in this period.');

    final headers = ['Date', 'Category', 'Description', 'Amount'];
    final data = expenses
        .map((exp) => [
              AppFormatters.formatDate(exp.date),
              exp.category,
              exp.description ?? '-',
              AppFormatters.formatCurrency(exp.amount, currency)
            ])
        .toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(color: lightGrey),
      headerStyle:
          pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: deepBlue),
      cellStyle: const pw.TextStyle(),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerRight,
      },
    );
  }
}
