import 'package:flutter/material.dart';
import 'package:personal_finance/helper/app_formater.dart';
import 'package:personal_finance/models/asset_model.dart';
import 'package:personal_finance/models/expense_model.dart';
import 'package:personal_finance/models/income_model.dart';
import 'package:personal_finance/controllers/insights_provider.dart';
import 'package:personal_finance/models/subscription_model.dart';
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
    required String currency,
    required List<Expense> expenses,
    required List<Income> incomes,
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
      pw.MultiPage(
        theme: theme,
        build: (pw.Context context) {
          return [
            pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'Financial Sheet',
                    style: pw.TextStyle(
                        fontSize: 40,
                        fontWeight: pw.FontWeight.bold,
                        color: deepBlue),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Period: ${AppFormatters.formatDate(dateRange.start)} - ${AppFormatters.formatDate(dateRange.end)}',
                    style: const pw.TextStyle(fontSize: 16, color: darkGrey),
                  ),
                ],
              ),
            )
          ];
        },
      ),
    );

    // 2. Highlights & Review of Operations
    doc.addPage(
      pw.MultiPage(
        maxPages: 100,
        theme: theme,
        header: (context) => pw.Header(
            level: 0,
            child: pw.Text('Report Highlights',
                style: pw.TextStyle(
                    fontSize: 20, fontWeight: pw.FontWeight.bold))),
        build: (pw.Context context) {
          final totalExpenses =
              spendingBreakdown.needs + spendingBreakdown.wants;
          final totalIncome =
              incomes.fold<double>(0, (sum, income) => sum + income.amount);
          final netFlow =
              totalIncome + spendingBreakdown.investments - totalExpenses;

          return [
            sectionHeader('Review of Operations'),
            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Income:'),
                pw.Text(AppFormatters.formatCurrency(totalIncome, currency),
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
              ],
            ),
            pw.SizedBox(height: 8),
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
        maxPages: 100,
        theme: theme,
        header: (context) => pw.Header(
            level: 0,
            child: pw.Text("Management's Discussion",
                style: pw.TextStyle(
                    fontSize: 20, fontWeight: pw.FontWeight.bold))),
        build: (pw.Context context) {
          final categoryTotals = _aggregateExpensesByCategory(expenses);
          return [
            sectionHeader("Director's Report"),
            pw.SizedBox(height: 16),
            _buildCategorySpendingChart(categoryTotals, currency, theme),
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
        maxPages: 100,
        theme: theme,
        header: (context) => pw.Header(
            level: 0,
            child: pw.Text('Detailed Transactions',
                style: pw.TextStyle(
                    fontSize: 20, fontWeight: pw.FontWeight.bold))),
        build: (pw.Context context) {
          return [_buildTransactionTable(expenses, incomes, currency)];
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
      List<Expense> expenses, List<Income> incomes, String currency) {
    if (expenses.isEmpty && incomes.isEmpty) {
      return pw.Text('No transactions in this period.');
    }

    // Combine expenses and incomes
    final allTransactions = <_Transaction>[];
    for (var exp in expenses) {
      allTransactions.add(_Transaction(
          date: exp.date,
          description: exp.description ?? '-',
          amount: exp.amount,
          type: _TransactionType.expense,
          category: exp.category));
    }
    for (var inc in incomes) {
      allTransactions.add(_Transaction(
          date: inc.date,
          description: inc.description,
          amount: inc.amount,
          type: _TransactionType.income,
          category: inc.source));
    }

    // Sort transactions by date
    allTransactions.sort((a, b) => a.date.compareTo(b.date));

    final headers = [
      'Date',
      'Category/Source',
      'Description',
      'Type',
      'Amount'
    ];
    final data = allTransactions
        .map((tx) => [
              AppFormatters.formatDate(tx.date),
              tx.category,
              tx.description,
              tx.type == _TransactionType.expense ? 'Expense' : 'Income',
              (tx.type == _TransactionType.expense ? '-' : '+') +
                  AppFormatters.formatCurrency(tx.amount, currency)
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
        3: pw.Alignment.center,
        4: pw.Alignment.centerRight,
      },
    );
  }

  static Map<String, double> _aggregateExpensesByCategory(
      List<Expense> expenses) {
    final Map<String, double> categoryTotals = {};
    for (var expense in expenses) {
      categoryTotals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    return categoryTotals;
  }

  static pw.Widget _buildCategorySpendingChart(
      Map<String, double> categoryTotals, String currency, pw.ThemeData theme) {
    if (categoryTotals.isEmpty) {
      return pw.Text('No category spending data for this period.');
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Sort descending

    final maxSpending =
        sortedCategories.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Spending by Category',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
        pw.SizedBox(height: 10),
        ...sortedCategories.map(
          (entry) {
            final category = entry.key;
            final amount = entry.value;
            final barWidth = (amount / maxSpending) * 200; // Max bar width 200

            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Row(
                children: [
                  pw.SizedBox(
                    width: 100,
                    child: pw.Text(category, style: theme.defaultTextStyle),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Container(
                    height: 10,
                    width: barWidth,
                    decoration: const pw.BoxDecoration(
                      color: mustardYellow,
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text(AppFormatters.formatCurrency(amount, currency),
                      style: theme.defaultTextStyle),
                ],
              ),
            );
          },
        ).toList(),
      ],
    );
  }
}

enum _TransactionType { income, expense }

class _Transaction {
  final DateTime date;
  final String description;
  final double amount;
  final _TransactionType type;
  final String category;

  _Transaction({
    required this.date,
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
  });
}
