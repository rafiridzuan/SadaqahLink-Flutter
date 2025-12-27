import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:sadaqahlink/models/donation_model.dart';
import 'package:sadaqahlink/services/database_service.dart';
import 'package:sadaqahlink/widgets/custom_loading.dart';
import 'package:sadaqahlink/utils/app_localizations.dart';

import 'package:sadaqahlink/widgets/date_range_selector.dart';

class StatisticsData {
  final double totalDonations;
  final double cashTotal;
  final double qrPayTotal;
  final Map<String, double> trendData; // Renamed from dailyTrend to be generic
  final String highestLabel; // Renamed from highestDay
  final double highestAmount; // Renamed from highestDayAmount
  final double average; // Renamed from averageDaily

  StatisticsData({
    required this.totalDonations,
    required this.cashTotal,
    required this.qrPayTotal,
    required this.trendData,
    required this.highestLabel,
    required this.highestAmount,
    required this.average,
  });
}

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  DateRangeOption _selectedOption = DateRangeOption.last7Days;
  DateTimeRange? _customRange;

  StatisticsData _calculateStatistics(
    List<Donation> donations,
    AppLocalizations localizations,
  ) {
    double total = 0;
    double cash = 0;
    double qrpay = 0;
    final Map<String, double> trendTotals = {};

    DateTime start;
    DateTime end;

    final now = DateTime.now();

    if (_selectedOption == DateRangeOption.custom && _customRange != null) {
      start = _customRange!.start;
      end = _customRange!.end
          .add(const Duration(days: 1))
          .subtract(const Duration(milliseconds: 1));
    } else {
      // Determine range based on option
      switch (_selectedOption) {
        case DateRangeOption.today:
          start = DateTime(now.year, now.month, now.day);
          end = start
              .add(const Duration(days: 1))
              .subtract(const Duration(milliseconds: 1));
          break;
        case DateRangeOption.yesterday:
          start = DateTime(now.year, now.month, now.day - 1);
          end = DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(const Duration(milliseconds: 1));
          break;
        case DateRangeOption.last7Days:
          start = now.subtract(const Duration(days: 7));
          end = now;
          break;
        case DateRangeOption.thisMonth:
          start = DateTime(now.year, now.month, 1);
          end = DateTime(
            now.year,
            now.month + 1,
            1,
          ).subtract(const Duration(milliseconds: 1));
          break;
        case DateRangeOption.thisYear:
          start = DateTime(now.year, 1, 1);
          end = DateTime(
            now.year + 1,
            1,
            1,
          ).subtract(const Duration(milliseconds: 1));
          break;
        default:
          start = DateTime(now.year, now.month, now.day); // Default today
          end = now;
      }
    }

    // Initialize trend keys
    bool isMonthly = _selectedOption == DateRangeOption.thisYear;
    bool isHourly = false;

    // Check if range is single day
    if (_selectedOption == DateRangeOption.today ||
        _selectedOption == DateRangeOption.yesterday ||
        (_selectedOption == DateRangeOption.custom &&
            start.year == end.year &&
            start.month == end.month &&
            start.day == end.day)) {
      isHourly = true;
    }

    bool isWeekly = _selectedOption == DateRangeOption.thisMonth;

    if (isMonthly) {
      for (int i = 1; i <= 12; i++) {
        final date = DateTime(now.year, i, 1);
        final key = DateFormat('MMM').format(date);
        trendTotals[key] = 0.0;
      }
    } else if (isWeekly) {
      // Weekly keys (Week 1, Week 2, Week 3, Week 4)
      for (int i = 0; i < 4; i++) {
        // Limit to 4 weeks
        final key = '${localizations.get('week')} ${i + 1}';
        trendTotals[key] = 0.0;
      }
    } else if (isHourly) {
      // Hourly keys (grouped by 4 hours: 00-04, 04-08, etc.)
      for (int i = 0; i < 6; i++) {
        final startHour = i * 4;
        final endHour = startHour + 4;
        final key =
            '${startHour.toString().padLeft(2, '0')}:00 - ${endHour.toString().padLeft(2, '0')}:00';
        trendTotals[key] = 0.0;
      }
    } else {
      // Daily keys
      int days = end.difference(start).inDays + 1;
      if (days > 31) days = 31; // Cap at 31 for daily view safety

      for (int i = 0; i < days; i++) {
        final date = start.add(Duration(days: i));
        final key = DateFormat('dd MMM').format(date);
        trendTotals[key] = 0.0;
      }
    }

    for (var donation in donations) {
      // Filter by range first
      if (donation.timestamp.isAfter(start) &&
          donation.timestamp.isBefore(end)) {
        total += donation.amount;
        if (donation.method.toLowerCase() == 'cash') {
          cash += donation.amount;
        } else {
          qrpay += donation.amount;
        }

        // Trend Data
        String key;
        if (isMonthly) {
          key = DateFormat('MMM').format(donation.timestamp);
        } else if (isWeekly) {
          // Calculate week number (1-based index roughly)
          // Simple approximation: (day / 7).ceil()
          int weekNum = ((donation.timestamp.day - 1) / 7).floor() + 1;
          if (weekNum > 4) weekNum = 4; // Cap at Week 4
          key = '${localizations.get('week')} $weekNum';
        } else if (isHourly) {
          int interval = donation.timestamp.hour ~/ 4;
          final startHour = interval * 4;
          final endHour = startHour + 4;
          key =
              '${startHour.toString().padLeft(2, '0')}:00 - ${endHour.toString().padLeft(2, '0')}:00';
        } else {
          key = DateFormat('dd MMM').format(donation.timestamp);
        }

        if (trendTotals.containsKey(key)) {
          trendTotals[key] = (trendTotals[key] ?? 0) + donation.amount;
        } else if (_selectedOption == DateRangeOption.custom) {
          // For custom range, if we didn't pre-populate (e.g. > 31 days but dynamic), add it
          trendTotals[key] = (trendTotals[key] ?? 0) + donation.amount;
        } else if (isWeekly) {
          // Ensure dynamic weeks (e.g. week 5) are added if logic above missed initialization (though we init 5)
          trendTotals[key] = (trendTotals[key] ?? 0) + donation.amount;
        }
      }
    }

    // Highest
    String highestLabel = 'N/A';
    double highestAmount = 0;
    if (trendTotals.isNotEmpty) {
      final highestEntry = trendTotals.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      highestLabel = highestEntry.key;
      highestAmount = highestEntry.value;
    }

    // Average
    double average = 0;
    if (trendTotals.isNotEmpty) {
      // Filter out zero values? Or count all?
      // user wants avg per unit (day/month)
      // If we pre-populated, length is fixed.
      final totalVal = trendTotals.values.fold(0.0, (a, b) => a + b);
      average = totalVal / trendTotals.length;
    }

    return StatisticsData(
      totalDonations: total,
      cashTotal: cash,
      qrPayTotal: qrpay,
      trendData: trendTotals,
      highestLabel: highestLabel,
      highestAmount: highestAmount,
      average: average,
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

  @override
  Widget build(BuildContext context) {
    final databaseService = DatabaseService();
    final localizations = AppLocalizations.of(context);

    // Date Range calculation for display
    final now = DateTime.now();
    DateTime displayStart = now;
    DateTime displayEnd = now;

    if (_selectedOption == DateRangeOption.custom && _customRange != null) {
      displayStart = _customRange!.start;
      displayEnd = _customRange!.end;
    } else {
      switch (_selectedOption) {
        case DateRangeOption.today:
          displayStart = DateTime(now.year, now.month, now.day);
          displayEnd = displayStart;
          break;
        case DateRangeOption.yesterday:
          displayStart = DateTime(now.year, now.month, now.day - 1);
          displayEnd = displayStart;
          break;
        case DateRangeOption.last7Days:
          displayStart = now.subtract(const Duration(days: 7));
          displayEnd = now;
          break;
        case DateRangeOption.thisMonth:
          displayStart = DateTime(now.year, now.month, 1);
          displayEnd = now;
          break;
        case DateRangeOption.thisYear:
          displayStart = DateTime(now.year, 1, 1);
          displayEnd = now;
          break;
        case DateRangeOption.custom:
          // Handled in if block above, but needed for exhaustive switch
          if (_customRange != null) {
            displayStart = _customRange!.start;
            displayEnd = _customRange!.end;
          }
          break;
      }
    }

    final dateFormat = DateFormat(
      'dd MMM yyyy',
      localizations.locale.toString(),
    );
    String dateRangeText;
    if (displayStart.year == displayEnd.year &&
        displayStart.month == displayEnd.month &&
        displayStart.day == displayEnd.day) {
      dateRangeText = dateFormat.format(displayStart);
    } else {
      dateRangeText =
          '${dateFormat.format(displayStart)} - ${dateFormat.format(displayEnd)}';
    }

    // Chart Title
    String chartTitle = localizations.get('weekly_trend');
    bool isSingleDay =
        displayStart.year == displayEnd.year &&
        displayStart.month == displayEnd.month &&
        displayStart.day == displayEnd.day;

    if (isSingleDay) {
      chartTitle = localizations.get('hourly_trend');
    } else if (_selectedOption == DateRangeOption.thisMonth) {
      chartTitle = localizations.get('monthly_trend');
    } else if (_selectedOption == DateRangeOption.thisYear) {
      chartTitle = localizations.get('yearly_trend');
    }

    return StreamBuilder<List<Donation>>(
      stream: databaseService.getDonations(),
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

        final donations = snapshot.data ?? [];
        final stats = _calculateStatistics(donations, localizations);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row (Page Title + Selector)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    localizations.get('statistics'),
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
              // Header Section (Matching Report Style)
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
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        dateRangeText,
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
              const SizedBox(height: 16),

              // Highlights
              Text(
                localizations.get('highlights'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildHighlightCard(
                        context,
                        localizations.get('highest_day'),
                        '${stats.highestLabel}\n(RM ${stats.highestAmount.toStringAsFixed(2)})',
                        Icons.trending_up,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildHighlightCard(
                        context,
                        localizations.get('daily_avg'),
                        'RM ${stats.average.toStringAsFixed(2)}',
                        Icons.analytics,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Trend Chart
              Text(
                // Use dynamic title
                chartTitle == "yearly_trend" ? "Yearly Trend" : chartTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: Theme.of(context).dividerColor.withOpacity(0.1),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    height: 250,
                    child: stats.trendData.isEmpty
                        ? Center(
                            child: Text(localizations.get('no_data_available')),
                          )
                        : BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: stats.trendData.values.isEmpty
                                  ? 100
                                  : (stats.trendData.values.reduce(
                                          (a, b) => a > b ? a : b,
                                        ) *
                                        1.2),
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipColor: (group) =>
                                      Theme.of(context).primaryColor,
                                  getTooltipItem:
                                      (group, groupIndex, rod, rodIndex) {
                                        return BarTooltipItem(
                                          'RM ${rod.toY.toStringAsFixed(2)}',
                                          const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      },
                                ),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 20,
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: Theme.of(
                                      context,
                                    ).dividerColor.withOpacity(0.1),
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index >= 0 &&
                                          index < stats.trendData.keys.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Transform.rotate(
                                            angle: -0.5,
                                            child: Text(
                                              stats.trendData.keys.elementAt(
                                                index,
                                              ),
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall?.color,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) {
                                      if (value == meta.max)
                                        return const SizedBox();
                                      return Text(
                                        'RM ${value.toInt()}',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: stats.trendData.entries
                                  .toList()
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                    return BarChartGroupData(
                                      x: entry.key,
                                      barRods: [
                                        BarChartRodData(
                                          toY: entry.value.value,
                                          gradient: LinearGradient(
                                            colors: [
                                              Theme.of(context).primaryColor,
                                              Theme.of(
                                                context,
                                              ).colorScheme.secondary,
                                            ],
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                          ),
                                          width: 16,
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(6),
                                              ),
                                        ),
                                      ],
                                    );
                                  })
                                  .toList(),
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Payment Methods
              Text(
                localizations.get('payment_methods'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: Theme.of(context).dividerColor.withOpacity(0.1),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 250,
                        child: stats.cashTotal + stats.qrPayTotal == 0
                            ? Center(
                                child: Text(
                                  localizations.get('no_data_available'),
                                ),
                              )
                            : PieChart(
                                PieChartData(
                                  sections: [
                                    PieChartSectionData(
                                      value: stats.cashTotal,
                                      title:
                                          '${((stats.cashTotal / (stats.cashTotal + stats.qrPayTotal)) * 100).toStringAsFixed(1)}%',
                                      color: const Color(0xFF00BCD4),
                                      radius: 80,
                                      titleStyle: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      badgeWidget: _buildBadge(
                                        Icons.money,
                                        const Color(0xFF00BCD4),
                                      ),
                                      badgePositionPercentageOffset: 1.2,
                                    ),
                                    PieChartSectionData(
                                      value: stats.qrPayTotal,
                                      title:
                                          '${((stats.qrPayTotal / (stats.cashTotal + stats.qrPayTotal)) * 100).toStringAsFixed(1)}%',
                                      color: const Color(0xFF1A237E),
                                      radius: 80,
                                      titleStyle: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      badgeWidget: _buildBadge(
                                        Icons.qr_code_2,
                                        const Color(0xFF1A237E),
                                      ),
                                      badgePositionPercentageOffset: 1.2,
                                    ),
                                  ],
                                  sectionsSpace: 4,
                                  centerSpaceRadius: 40,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegendItem(
                            context,
                            'Cash',
                            const Color(0xFF00BCD4),
                          ),
                          const SizedBox(width: 24),
                          _buildLegendItem(
                            context,
                            'QR Pay',
                            const Color(0xFF1A237E),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Export Button
              const SizedBox(height: 32),
            ],
          ).animate().fadeIn(duration: 500.ms),
        );
      },
    );
  }

  Widget _buildHighlightCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors
            .white, // Keep white for badge background to ensure icon visibility
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }

  Widget _buildLegendItem(BuildContext context, String text, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }
}
