import 'package:flutter/material.dart';
import 'package:sadaqahlink/widgets/background_wrapper.dart';
import 'package:sadaqahlink/widgets/blurred_app_bar.dart';
import 'package:intl/intl.dart';
import 'package:sadaqahlink/models/donation_model.dart';
import 'package:sadaqahlink/services/database_service.dart';
import 'package:sadaqahlink/widgets/transaction_tile.dart';
import 'package:sadaqahlink/widgets/custom_loading.dart';
import 'package:sadaqahlink/widgets/date_range_selector.dart';

import 'package:sadaqahlink/utils/app_localizations.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  DateRangeOption _selectedOption =
      DateRangeOption.last7Days; // Default to last 7 days
  DateTimeRange? _customRange;

  List<Donation> _filterDonations(List<Donation> donations) {
    final now = DateTime.now();

    switch (_selectedOption) {
      case DateRangeOption.today:
        final todayStart = DateTime(now.year, now.month, now.day);
        final todayEnd = todayStart
            .add(const Duration(days: 1))
            .subtract(const Duration(milliseconds: 1));
        return donations
            .where(
              (d) =>
                  d.timestamp.isAfter(todayStart) &&
                  d.timestamp.isBefore(todayEnd),
            )
            .toList();

      case DateRangeOption.yesterday:
        final yesterdayStart = DateTime(now.year, now.month, now.day - 1);
        final yesterdayEnd = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(milliseconds: 1));
        return donations
            .where(
              (d) =>
                  d.timestamp.isAfter(yesterdayStart) &&
                  d.timestamp.isBefore(yesterdayEnd),
            )
            .toList();

      case DateRangeOption.last7Days:
        final last7DaysStart = now.subtract(const Duration(days: 7));
        return donations
            .where((d) => d.timestamp.isAfter(last7DaysStart))
            .toList();

      case DateRangeOption.thisMonth:
        final monthStart = DateTime(now.year, now.month, 1);
        return donations.where((d) => d.timestamp.isAfter(monthStart)).toList();

      case DateRangeOption.thisYear:
        final yearStart = DateTime(now.year, 1, 1);
        return donations.where((d) => d.timestamp.isAfter(yearStart)).toList();

      case DateRangeOption.custom:
        if (_customRange != null) {
          final start = DateTime(
            _customRange!.start.year,
            _customRange!.start.month,
            _customRange!.start.day,
          );
          final end = DateTime(
            _customRange!.end.year,
            _customRange!.end.month,
            _customRange!.end.day,
            23,
            59,
            59,
          );
          return donations.where((d) {
            return d.timestamp.isAfter(start) && d.timestamp.isBefore(end);
          }).toList();
        }
        return donations;
    }
  }

  Map<String, List<Donation>> _groupDonationsByWeek(List<Donation> donations) {
    final Map<String, List<Donation>> grouped = {};
    for (var donation in donations) {
      final weekNum = ((donation.timestamp.day - 1) ~/ 7) + 1;
      final key = 'Week $weekNum';
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(donation);
    }
    final sortedKeys = grouped.keys.toList()..sort();
    return Map.fromEntries(
      sortedKeys.map((key) => MapEntry(key, grouped[key]!)),
    );
  }

  Map<String, List<Donation>> _groupDonationsByMonth(List<Donation> donations) {
    final Map<String, List<Donation>> grouped = {};
    for (var donation in donations) {
      final key = DateFormat('MMMM').format(donation.timestamp);
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(donation);
    }
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final dateA = DateFormat('MMMM').parse(a);
        final dateB = DateFormat('MMMM').parse(b);
        return dateA.month.compareTo(dateB.month);
      });
    return Map.fromEntries(
      sortedKeys.map((key) => MapEntry(key, grouped[key]!)),
    );
  }

  void _onRangeSelected(DateRangeOption option, DateTimeRange? range) {
    setState(() {
      _selectedOption = option;
      if (range != null) {
        _customRange = range;
      }
    });
  }

  String _getDateRangeString() {
    final localizations = AppLocalizations.of(context);
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    if (_selectedOption == DateRangeOption.custom && _customRange != null) {
      start = _customRange!.start;
      end = _customRange!.end;
    } else {
      switch (_selectedOption) {
        case DateRangeOption.today:
          start = DateTime(now.year, now.month, now.day);
          end = start;
          break;
        case DateRangeOption.yesterday:
          start = DateTime(now.year, now.month, now.day - 1);
          end = start;
          break;
        case DateRangeOption.last7Days:
          start = now.subtract(const Duration(days: 7));
          end = now;
          break;
        case DateRangeOption.thisMonth:
          start = DateTime(now.year, now.month, 1);
          end = now;
          break;
        case DateRangeOption.thisYear:
          start = DateTime(now.year, 1, 1);
          end = now;
          break;
        default:
          return '';
      }
    }
    final dateFormat = DateFormat(
      'dd MMM yyyy',
      localizations.locale.toString(),
    );
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return dateFormat.format(start);
    }
    return '${dateFormat.format(start)} - ${dateFormat.format(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final databaseService = DatabaseService();
    final localizations = AppLocalizations.of(context);

    return BackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BlurredAppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(localizations.get('transactions')),
              Text(
                _getDateRangeString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.white70, // Always white-ish on dark App Bar
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            DateRangeSelector(
              selectedOption: _selectedOption,
              customRange: _customRange,
              onRangeSelected: _onRangeSelected,
              compact: true,
              compactIconColor: Colors.white, // Always white on dark App Bar
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // Big Header Section (Matching Report Style)
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
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  // Background color removed
                ),
                child: Column(
                  children: [
                    Text(
                      _getDateRangeString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),

            // Transactions List
            Expanded(
              child: StreamBuilder<List<Donation>>(
                stream: databaseService.getDonations(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CustomLoadingWidget());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final allDonations = snapshot.data ?? [];
                  final filteredDonations = _filterDonations(allDonations);
                  final total = filteredDonations.fold<double>(
                    0.0,
                    (sum, d) => sum + d.amount,
                  );

                  return Column(
                    children: [
                      // Summary
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        color: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withOpacity(0.1),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${filteredDonations.length} ${localizations.get('transactions').toLowerCase()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Total: RM ${total.toStringAsFixed(2)}', // TODO: Localize 'Total'
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // List
                      Expanded(
                        child: filteredDonations.isEmpty
                            ? Center(
                                child: Text(
                                  localizations.get('no_transactions_found'),
                                ),
                              )
                            : _buildTransactionList(filteredDonations),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(List<Donation> donations) {
    if (_selectedOption == DateRangeOption.thisMonth) {
      final grouped = _groupDonationsByWeek(donations);
      return ListView.builder(
        itemCount: grouped.length,
        itemBuilder: (context, index) {
          final key = grouped.keys.elementAt(index);
          final groupDonations = grouped[key]!;
          final groupTotal = groupDonations.fold<double>(
            0.0,
            (sum, d) => sum + d.amount,
          );

          return ExpansionTile(
            title: Text(
              key.replaceAll('Week', AppLocalizations.of(context).get('week')),
            ),
            subtitle: Text('Total: RM ${groupTotal.toStringAsFixed(2)}'),
            children: groupDonations
                .map((d) => TransactionTile(donation: d))
                .toList(),
          );
        },
      );
    } else if (_selectedOption == DateRangeOption.thisYear) {
      final grouped = _groupDonationsByMonth(donations);
      return ListView.builder(
        itemCount: grouped.length,
        itemBuilder: (context, index) {
          final key = grouped.keys.elementAt(index);
          final groupDonations = grouped[key]!;
          final groupTotal = groupDonations.fold<double>(
            0.0,
            (sum, d) => sum + d.amount,
          );

          return ExpansionTile(
            title: Text(key),
            subtitle: Text('Total: RM ${groupTotal.toStringAsFixed(2)}'),
            children: groupDonations
                .map((d) => TransactionTile(donation: d))
                .toList(),
          );
        },
      );
    } else {
      return ListView.separated(
        itemCount: donations.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          return TransactionTile(donation: donations[index]);
        },
      );
    }
  }
}
