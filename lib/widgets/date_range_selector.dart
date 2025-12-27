import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sadaqahlink/utils/app_localizations.dart';

enum DateRangeOption {
  today,
  yesterday,
  last7Days,
  thisMonth,
  thisYear,
  custom,
}

class DateRangeSelector extends StatelessWidget {
  final DateRangeOption selectedOption;
  final DateTimeRange? customRange;
  final Function(DateRangeOption option, DateTimeRange? range) onRangeSelected;

  final bool compact;

  const DateRangeSelector({
    super.key,
    required this.selectedOption,
    required this.onRangeSelected,
    this.customRange,
    this.compact = false,
    this.compactIconColor,
  });

  final Color? compactIconColor;

  String _getLabel(BuildContext context, DateRangeOption option) {
    final localizations = AppLocalizations.of(context);
    switch (option) {
      case DateRangeOption.today:
        return localizations.get('today');
      case DateRangeOption.yesterday:
        return localizations.get('yesterday');
      case DateRangeOption.last7Days:
        return localizations.get('last_7_days');
      case DateRangeOption.thisMonth:
        return localizations.get('this_month');
      case DateRangeOption.thisYear:
        return localizations.get('this_year');
      case DateRangeOption.custom:
        return localizations.get('custom');
    }
  }

  static void show(
    BuildContext context, {
    required DateRangeOption selectedOption,
    required Function(DateRangeOption option, DateTimeRange? range)
    onRangeSelected,
    DateTimeRange? customRange,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ...DateRangeOption.values.map((option) {
                final isSelected = selectedOption == option;
                // Helper to get label without context instance
                String label = '';
                final localizations = AppLocalizations.of(context);
                switch (option) {
                  case DateRangeOption.today:
                    label = localizations.get('today');
                    break;
                  case DateRangeOption.yesterday:
                    label = localizations.get('yesterday');
                    break;
                  case DateRangeOption.last7Days:
                    label = localizations.get('last_7_days');
                    break;
                  case DateRangeOption.thisMonth:
                    label = localizations.get('this_month');
                    break;
                  case DateRangeOption.thisYear:
                    label = localizations.get('this_year');
                    break;
                  case DateRangeOption.custom:
                    label = localizations.get('custom');
                    break;
                }

                return ListTile(
                  title: Text(
                    label,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? (Theme.of(context).brightness == Brightness.dark
                                ? Colors.lightBlueAccent
                                : Theme.of(context).primaryColor)
                          : null,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.lightBlueAccent
                              : Theme.of(context).primaryColor,
                        )
                      : null,
                  onTap: () async {
                    Navigator.pop(context);
                    if (option == DateRangeOption.custom) {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDateRange: customRange,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: Theme.of(
                                context,
                              ).colorScheme.copyWith(onPrimary: Colors.white),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        onRangeSelected(option, picked);
                      }
                    } else {
                      onRangeSelected(option, null);
                    }
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showSelectionSheet(BuildContext context) {
    show(
      context,
      selectedOption: selectedOption,
      onRangeSelected: onRangeSelected,
      customRange: customRange,
    );
  }

  @override
  Widget build(BuildContext context) {
    String displayText = _getLabel(context, selectedOption);
    if (selectedOption == DateRangeOption.custom && customRange != null) {
      displayText =
          '${DateFormat('dd/MM').format(customRange!.start)} - ${DateFormat('dd/MM').format(customRange!.end)}';
    }

    if (compact) {
      return IconButton(
        onPressed: () => _showSelectionSheet(context),
        icon: Icon(
          Icons.calendar_month, // Use filled or outlined based on theme?
          color:
              compactIconColor ??
              (Theme.of(context).brightness == Brightness.dark
                  ? Colors.lightBlueAccent
                  : Theme.of(context).primaryColor),
        ),
        tooltip: displayText, // Show current selection on long press
      );
    }

    return GestureDetector(
      onTap: () => _showSelectionSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color:
              Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              size: 18,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              displayText,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ],
        ),
      ),
    );
  }
}
