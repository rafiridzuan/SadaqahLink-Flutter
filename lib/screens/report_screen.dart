import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:sadaqahlink/models/donation_model.dart';
import 'package:sadaqahlink/services/database_service.dart';
import 'package:sadaqahlink/widgets/custom_loading.dart';
import 'package:sadaqahlink/widgets/date_range_selector.dart';

import 'package:sadaqahlink/utils/app_localizations.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final DatabaseService _databaseService = DatabaseService();
  DateRangeOption _selectedOption = DateRangeOption
      .last7Days; // Default to last 7 days for report? Or today? user changed request to user choice. Let's default to Last 7 days as it was "Weekly" before
  DateTimeRange? _customRange;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _recalculateDateRange();
  }

  void _recalculateDateRange() {
    final now = DateTime.now();
    if (_selectedOption == DateRangeOption.custom && _customRange != null) {
      _startDate = _customRange!.start;
      _endDate = _customRange!.end
          .add(const Duration(days: 1))
          .subtract(const Duration(milliseconds: 1));
    } else {
      switch (_selectedOption) {
        case DateRangeOption.today:
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = _startDate
              .add(const Duration(days: 1))
              .subtract(const Duration(milliseconds: 1));
          break;
        case DateRangeOption.yesterday:
          _startDate = DateTime(now.year, now.month, now.day - 1);
          _endDate = DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(const Duration(milliseconds: 1));
          break;
        case DateRangeOption.last7Days:
          _startDate = now.subtract(const Duration(days: 7));
          _endDate = now;
          break;
        case DateRangeOption.thisMonth:
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = DateTime(
            now.year,
            now.month + 1,
            1,
          ).subtract(const Duration(milliseconds: 1));
          break;
        case DateRangeOption.thisYear:
          _startDate = DateTime(now.year, 1, 1);
          _endDate = DateTime(
            now.year + 1,
            1,
            1,
          ).subtract(const Duration(milliseconds: 1));
          break;
        default: // Fallback to weekly/last 7 days logic if needed or just today
          _startDate = now.subtract(const Duration(days: 7));
          _endDate = now;
      }
    }
  }

  void _onRangeSelected(DateRangeOption option, DateTimeRange? range) {
    setState(() {
      _selectedOption = option;
      if (range != null) {
        _customRange = range;
      }
      _recalculateDateRange();
    });
  }

  List<Donation> _filterDonations(List<Donation> donations) {
    return donations.where((d) {
      return d.timestamp.isAfter(_startDate) && d.timestamp.isBefore(_endDate);
    }).toList();
  }

  Future<void> _printReport(
    List<Donation> filteredDonations,
    double totalAmount,
    AppLocalizations localizations,
  ) async {
    final doc = pw.Document();
    final dateFormat = DateFormat(
      'dd/MM/yyyy',
      localizations.locale.toString(),
    );
    final timeFormat = DateFormat('HH:mm');
    final currencyFormat = NumberFormat.currency(
      symbol: 'RM ',
      decimalDigits: 2,
    );

    String reportTitle = localizations.get('weekly_donation_report');
    // Adjust title based on range? Or just "Donation Report"
    // Let's make it generic "Donation Report" + Date Range
    // But keeping existing string key for now unless I update arb
    // I'll stick to a generic header in code for now or reuse the existing key if it means "Donation Report"

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'SadaqahLink',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(reportTitle, style: const pw.TextStyle(fontSize: 18)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '${localizations.get('date_range')}:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  '${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}',
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '${localizations.get('generated_on')}:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())),
              ],
            ),
            pw.SizedBox(height: 30),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Text(
                        localizations.get('total_donation'),
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        currencyFormat.format(totalAmount),
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text(
                        localizations.get('total_transaction'),
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '${filteredDonations.length}',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),
            pw.Text(
              localizations.get('transactions'),
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              context: context,
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              headerHeight: 25,
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
              },
              headers: [
                localizations.get('date'),
                localizations.get('time'),
                localizations.get('method'),
                localizations.get('amount'),
              ],
              data: filteredDonations.map((d) {
                return [
                  dateFormat.format(d.timestamp),
                  timeFormat.format(d.timestamp),
                  d.method.toUpperCase(),
                  currencyFormat.format(d.amount),
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final dateFormat = DateFormat(
      'dd MMM yyyy',
      localizations.locale.toString(),
    );
    final currencyFormat = NumberFormat.currency(
      symbol: 'RM ',
      decimalDigits: 2,
    );

    return StreamBuilder<List<Donation>>(
      stream: _databaseService.getDonations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CustomLoadingWidget()),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allDonations = snapshot.data ?? [];
        final filteredDonations = _filterDonations(allDonations);
        final totalAmount = filteredDonations.fold(
          0.0,
          (sum, item) => sum + item.amount,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    localizations.get('reports'),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Theme.of(context).primaryColor,
                    ),
                  ),
                  DateRangeSelector(
                    selectedOption: _selectedOption,
                    customRange: _customRange,
                    onRangeSelected: _onRangeSelected,
                    compact: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Header Section
              GestureDetector(
                onTap: () => DateRangeSelector.show(
                  context,
                  selectedOption: _selectedOption,
                  onRangeSelected: _onRangeSelected,
                  customRange: _customRange,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    // Background color removed
                    // Border removed
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontSize: 20, // Increased size
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ... rest of UI (Print Button, Summary, List)
              // Print Button
              ElevatedButton.icon(
                onPressed: () =>
                    _printReport(filteredDonations, totalAmount, localizations),
                icon: Icon(
                  Icons.print,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.blueAccent
                      : Colors.white,
                ),
                label: Text(
                  localizations.get('print_report'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.blueAccent
                        : Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                      ? Colors.transparent
                      : Theme.of(context).primaryColor,
                  foregroundColor:
                      Theme.of(context).brightness == Brightness.dark
                      ? Colors.blueAccent
                      : Colors.white,
                  elevation: Theme.of(context).brightness == Brightness.dark
                      ? 0
                      : 4,
                  shadowColor: Theme.of(context).primaryColor.withOpacity(0.4),
                  side: Theme.of(context).brightness == Brightness.dark
                      ? const BorderSide(color: Colors.blueAccent, width: 2)
                      : BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Summary Cards
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        localizations.get('total_donation'),
                        currencyFormat.format(totalAmount),
                        Icons.attach_money,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        localizations.get('total_transaction'),
                        '${filteredDonations.length}',
                        Icons.receipt_long,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Detailed Transactions Header
              Text(
                localizations.get('transactions'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 12),

              // Transactions List
              filteredDonations.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).cardTheme.color ??
                            Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        localizations.get('no_transactions_found'),
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredDonations.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final donation = filteredDonations[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: donation.method == 'cash'
                                ? Colors.green.withOpacity(0.1)
                                : Colors.blue.withOpacity(0.1),
                            child: Icon(
                              donation.method == 'cash'
                                  ? Icons.money
                                  : Icons.qr_code,
                              color: donation.method == 'cash'
                                  ? Colors.green
                                  : Colors.blue,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            currencyFormat.format(donation.amount),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            DateFormat(
                              'dd MMM yyyy, HH:mm',
                            ).format(donation.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              donation.method.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ).animate().fadeIn(duration: 500.ms),
        );
      },
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
