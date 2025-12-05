import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:personal_finance/controllers/insights_provider.dart';
import 'package:personal_finance/models/asset_model.dart';
import 'package:personal_finance/models/expense_model.dart';
import 'package:personal_finance/models/income_model.dart';
import 'package:personal_finance/helper/report_repo.dart';
import 'package:personal_finance/models/subscription_model.dart';
import 'package:printing/printing.dart';

import 'app_formater.dart';

class ReportExporter {
  static Future<void> generateAndShareReport({
    required DateTimeRange dateRange,
    required String currency,
    required List<Expense> expenses,
    required List<Income> incomes,
    required SpendingBreakdown spendingBreakdown,
    required List<Asset> assets,
    required List<Subscription> subscriptions,
    required Map<String, double> budgetData,
    required List<CashFlowData> cashFlowData,
  }) async {
    final pdf = pw.Document();

    // --- THEME AND FONTS ---
    final font = await PdfGoogleFonts.openSansRegular();
    final boldFont = await PdfGoogleFonts.openSansBold();
    final logo = pw.MemoryImage(
      (await rootBundle.load('assets/icon/app_icon.png')).buffer.asUint8List(),
    );

    const accentColor = PdfColor.fromInt(0xFFFFEADD); // Light Peach
    const accentColorDark = PdfColor.fromInt(0xFFF57C00); // Warm Orange
    final grayColor = PdfColor.fromHex('#EEEEEE');
    final textColor = PdfColor.fromHex('#1A202C');

    final theme = pw.ThemeData.withFont(
      base: font,
      bold: boldFont,
    ).copyWith(
      defaultTextStyle: pw.TextStyle(color: textColor, fontSize: 10),
      header0: pw.TextStyle(
          fontSize: 24, fontWeight: pw.FontWeight.bold, color: textColor),
      header1: pw.TextStyle(
          fontSize: 20, fontWeight: pw.FontWeight.bold, color: textColor),
      header2: pw.TextStyle(
          fontSize: 16, fontWeight: pw.FontWeight.bold, color: textColor),
    );

    // --- PDF CONTENT ---
    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildHeader(context, logo),
        footer: _buildFooter,
        build: (context) => [
          _buildTitle(context, dateRange),
          pw.SizedBox(height: 20),
          _buildSummary(context, currency, spendingBreakdown),
          pw.SizedBox(height: 20),
          _buildCashFlowChart(context, currency, cashFlowData),
          pw.SizedBox(height: 20),
          _buildSpendingBreakdown(context, currency, expenses, accentColor),
          pw.SizedBox(height: 20),
          _buildNetWorth(context, currency, assets),
          pw.SizedBox(height: 20),
          _buildRecurringCosts(context, currency, subscriptions),
          pw.SizedBox(height: 20),
          _buildTransactionList(
              context, currency, expenses, incomes, accentColor),
        ],
      ),
    );

    await Printing.sharePdf(
        bytes: await pdf.save(), filename: 'financial_report.pdf');
  }

  static pw.Widget _buildHeader(pw.Context context, pw.ImageProvider logo) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200)),
      ),
      padding: const pw.EdgeInsets.only(bottom: 8),
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(children: [
            pw.Image(logo, height: 30),
            pw.SizedBox(width: 10),
            pw.Text('Financial Report',
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          ]),
          pw.Text(AppFormatters.formatDate(DateTime.now())),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: const pw.TextStyle(color: PdfColors.grey, fontSize: 8),
      ),
    );
  }

  static pw.Widget _buildTitle(pw.Context context, DateTimeRange dateRange) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Financial Summary', style: pw.Theme.of(context).header0),
        pw.SizedBox(height: 4),
        pw.Text(
          'For the period: ${AppFormatters.formatDate(dateRange.start)} - ${AppFormatters.formatDate(dateRange.end)}',
          style: pw.TextStyle(color: PdfColors.grey600, fontSize: 12),
        ),
      ],
    );
  }

  static pw.Widget _buildSummary(pw.Context context, String currency,
      SpendingBreakdown spendingBreakdown) {
    final totalExpenses = spendingBreakdown.needs + spendingBreakdown.wants;
    final netFlow = spendingBreakdown.income -
        totalExpenses -
        spendingBreakdown.investments;

    return pw.Column(
      children: [
        pw.Row(
          children: [
            _buildMetricCard(
                context,
                'Total Income',
                AppFormatters.formatCurrency(
                    spendingBreakdown.income, currency),
                color: PdfColors.green),
            pw.SizedBox(width: 10),
            _buildMetricCard(context, 'Total Spending',
                AppFormatters.formatCurrency(totalExpenses, currency),
                color: PdfColors.red),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            _buildMetricCard(
                context,
                'Total Savings',
                AppFormatters.formatCurrency(
                    spendingBreakdown.investments, currency),
                color: PdfColors.blue),
            pw.SizedBox(width: 10),
            _buildMetricCard(context, 'Net Flow',
                AppFormatters.formatCurrency(netFlow, currency),
                color: netFlow >= 0 ? PdfColors.teal : PdfColors.orange),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildMetricCard(
      pw.Context context, String title, String value,
      {required PdfColor color}) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: color.shade(0.1),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title,
                style: pw.TextStyle(
                    color: color.shade(0.9), fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text(value,
                style: pw.TextStyle(
                    color: color.shade(0.9),
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 18)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildSpendingBreakdown(pw.Context context, String currency,
      List<Expense> expenses, PdfColor headerColor) {
    final Map<String, double> categoryTotals = {};
    for (var expense in expenses) {
      categoryTotals.update(expense.category, (value) => value + expense.amount,
          ifAbsent: () => expense.amount);
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Spending Breakdown', style: pw.Theme.of(context).header2),
        pw.SizedBox(height: 10),
        pw.Text(
            'This table shows how your spending was distributed across different categories during the selected period.',
            style: const pw.TextStyle(color: PdfColors.grey700)),
        pw.SizedBox(height: 10),
        _buildDataTable(
          context,
          headers: ['Category', 'Amount', 'Percentage'],
          data: sortedCategories.map((entry) {
            final totalSpending =
                expenses.fold(0.0, (sum, e) => sum + e.amount);
            final percentage =
                totalSpending > 0 ? (entry.value / totalSpending) * 100 : 0.0;
            return [
              entry.key,
              AppFormatters.formatCurrency(entry.value, currency),
              '${percentage.toStringAsFixed(1)}%',
            ];
          }).toList(),
          headerColor: headerColor,
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
          },
          cellAlignments: {
            1: pw.Alignment.centerRight,
            2: pw.Alignment.centerRight,
          },
        ),
      ],
    );
  }

  static pw.Widget _buildNetWorth(
      pw.Context context, String currency, List<Asset> assets) {
    final totalAssets = assets.fold(0.0, (sum, asset) => sum + asset.value);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Asset Summary', style: pw.Theme.of(context).header2),
        pw.SizedBox(height: 10),
        pw.Text(
            'A summary of your recorded assets. Note: This does not include liabilities for a full net worth calculation.',
            style: const pw.TextStyle(color: PdfColors.grey700)),
        pw.SizedBox(height: 10),
        ...assets.map((asset) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(asset.name),
                  pw.Text(AppFormatters.formatCurrency(asset.value, currency),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
            )),
        pw.Divider(height: 20),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Total Asset Value',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(AppFormatters.formatCurrency(totalAssets, currency),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildRecurringCosts(
      pw.Context context, String currency, List<Subscription> subscriptions) {
    final totalMonthlyCost =
        subscriptions.fold(0.0, (sum, sub) => sum + sub.amount);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Recurring Costs (Subscriptions)',
            style: pw.Theme.of(context).header2),
        pw.SizedBox(height: 10),
        ...subscriptions.map((sub) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(sub.name),
                  pw.Text(AppFormatters.formatCurrency(sub.amount, currency),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
            )),
        pw.Divider(height: 20),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Total Monthly Recurring Costs',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(AppFormatters.formatCurrency(totalMonthlyCost, currency),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTransactionList(pw.Context context, String currency,
      List<Expense> expenses, List<Income> incomes, PdfColor headerColor) {
    final allTransactions = <Map<String, dynamic>>[];
    for (var e in expenses) {
      allTransactions.add({
        'date': e.date,
        'description': e.description,
        'category': e.category,
        'amount': -e.amount,
      });
    }
    for (var i in incomes) {
      allTransactions.add({
        'date': i.date,
        'description': i.description,
        'category': i.source,
        'amount': i.amount,
      });
    }

    allTransactions
        .sort((a, b) => (b['date'] as DateTime).compareTo(a['date']));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Transaction Log', style: pw.Theme.of(context).header2),
        pw.SizedBox(height: 10),
        _buildDataTable(
          context,
          headers: ['Date', 'Description', 'Category', 'Amount'],
          data: allTransactions.map((t) {
            final amount = t['amount'] as double;
            return [
              AppFormatters.formatDate(t['date']),
              t['description'],
              t['category'],
              pw.Text(
                AppFormatters.formatCurrency(amount, currency),
                style: pw.TextStyle(
                    color: amount >= 0 ? PdfColors.green : PdfColors.red),
              ),
            ];
          }).toList(),
          headerColor: headerColor,
          columnWidths: {
            0: const pw.FlexColumnWidth(1.5),
            1: const pw.FlexColumnWidth(3),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(1.5),
          },
          cellAlignments: {
            3: pw.Alignment.centerRight,
          },
        ),
      ],
    );
  }

  static pw.Widget _buildDataTable(
    pw.Context context, {
    required List<String> headers,
    required List<List<dynamic>> data,
    required PdfColor headerColor,
    Map<int, pw.TableColumnWidth>? columnWidths,
    Map<int, pw.Alignment> cellAlignments = const {},
  }) {
    final tableHeaders = headers.asMap().entries.map((entry) {
      final alignment = cellAlignments[entry.key] ?? pw.Alignment.centerLeft;
      return pw.Container(
        alignment: alignment,
        padding: const pw.EdgeInsets.all(5),
        child: pw.Text(entry.value,
            style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
                fontSize: 10)),
      );
    }).toList();

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey200, width: 1),
      columnWidths: columnWidths,
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: headerColor),
          children: tableHeaders,
        ),
        ...List<pw.TableRow>.generate(
          data.length,
          (rowIndex) {
            final row = data[rowIndex];
            return pw.TableRow(
              decoration: pw.BoxDecoration(
                color: rowIndex % 2 != 0
                    ? PdfColor.fromHex('#FAFAFA')
                    : PdfColors.white,
              ),
              children: List<pw.Widget>.generate(
                row.length,
                (colIndex) {
                  final cellData = row[colIndex];
                  final alignment =
                      cellAlignments[colIndex] ?? pw.Alignment.centerLeft;

                  final child = cellData is pw.Widget
                      ? cellData
                      : pw.Text(cellData.toString(),
                          style: const pw.TextStyle(fontSize: 9));

                  return pw.Container(
                    alignment: alignment,
                    padding: const pw.EdgeInsets.all(5),
                    child: child,
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  static pw.Widget _buildCashFlowChart(
    pw.Context context,
    String currency,
    List<CashFlowData> cashFlowData,
  ) {
    // If there is no data, we cannot draw a chart.
    if (cashFlowData.isEmpty) {
      return pw.Container();
    }

    // Find the absolute maximum value across all data points.
    final maxValue = cashFlowData
        .map((d) => math.max(d.income, d.expenses))
        .reduce(math.max);

    // If the maximum value is zero, the chart has no data to plot.
    // Skip rendering to prevent division-by-zero errors in the PDF library.
    if (maxValue <= 0) {
      return pw.Container();
    }
    var yAxisMax = maxValue * 1.2;
    const incomeColor = PdfColors.green;
    const expenseColor = PdfColors.red;

    final chart = pw.Chart(
      left: pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(right: 5),
        child: pw.Transform.rotate(
          angle: math.pi / 2,
          child: pw.Text('Amount ($currency)',
              style: const pw.TextStyle(fontSize: 8)),
        ),
      ),
      bottom: pw.Container(
        margin: const pw.EdgeInsets.only(top: 5),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
          children: [
            pw.Row(children: [
              pw.Container(width: 10, height: 10, color: incomeColor),
              pw.SizedBox(width: 5),
              pw.Text('Income', style: const pw.TextStyle(fontSize: 8)),
            ]),
            pw.Row(children: [
              pw.Container(width: 10, height: 10, color: expenseColor),
              pw.SizedBox(width: 5),
              pw.Text('Expenses', style: const pw.TextStyle(fontSize: 8)),
            ]),
          ],
        ),
      ),
      grid: pw.CartesianGrid(
        xAxis: pw.FixedAxis.fromStrings(
          cashFlowData
              .map<String>(
                  (d) => AppFormatters.getMonthName(d.month, short: true))
              .toList(),
          ticks: true,
        ),
        yAxis: pw.FixedAxis(
          [0, yAxisMax / 2, yAxisMax],
          format: (v) => AppFormatters.formatCurrency(
              v.toDouble(), ''), // No currency symbol on axis
          divisions: true,
        ),
      ),
      datasets: [
        pw.BarDataSet<pw.PointChartValue>(
          color: incomeColor,
          width: 15,
          data: List.generate(
            cashFlowData.length,
            (i) => pw.PointChartValue(i.toDouble(), cashFlowData[i].income),
          ),
        ),
        pw.BarDataSet<pw.PointChartValue>(
          color: expenseColor,
          width: 15,
          data: List.generate(
            cashFlowData.length,
            (i) => pw.PointChartValue(i.toDouble(), cashFlowData[i].expenses),
          ),
        ),
      ],
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Monthly Cash Flow', style: pw.Theme.of(context).header2),
        pw.SizedBox(height: 10),
        pw.Text(
            'This chart visualizes your total income versus total expenses for each month in the selected period.',
            style: const pw.TextStyle(color: PdfColors.grey700)),
        pw.SizedBox(height: 20),
        pw.SizedBox(
          height: 200,
          child: chart,
        ),
      ],
    );
  }
}
