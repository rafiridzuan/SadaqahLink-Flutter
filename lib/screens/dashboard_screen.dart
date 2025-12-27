import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sadaqahlink/models/donation_model.dart';
import 'package:sadaqahlink/services/database_service.dart';
import 'package:sadaqahlink/screens/transactions_screen.dart';
import 'package:sadaqahlink/widgets/custom_loading.dart';
import 'package:sadaqahlink/widgets/summary_card.dart';
import 'package:sadaqahlink/widgets/transaction_tile.dart';
import 'package:sadaqahlink/utils/app_localizations.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  double _calculateTotal(List<Donation> donations) {
    return donations.fold(0.0, (sum, donation) => sum + donation.amount);
  }

  double _calculateToday(List<Donation> donations) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return donations
        .where((d) => d.timestamp.isAfter(today))
        .fold(0.0, (sum, donation) => sum + donation.amount);
  }

  double _calculateMonth(List<Donation> donations) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    return donations
        .where((d) => d.timestamp.isAfter(monthStart))
        .fold(0.0, (sum, donation) => sum + donation.amount);
  }

  @override
  Widget build(BuildContext context) {
    final databaseService = DatabaseService();
    final localizations = AppLocalizations.of(context);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<List<Donation>>(
              stream: databaseService.getDonations(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 300,
                    child: CustomLoadingWidget(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final donations = snapshot.data ?? [];
                final total = _calculateTotal(donations);
                final today = _calculateToday(donations);
                final month = _calculateMonth(donations);
                final recent = donations.take(5).toList();

                final screenWidth = MediaQuery.of(context).size.width;
                final itemWidth = (screenWidth - 48) / 2;
                const itemHeight = 140.0; // Fixed height for consistency
                final childAspectRatio = itemWidth / itemHeight;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 140,
                                child: SummaryCard(
                                  title: localizations.get('total'),
                                  value: 'RM ${total.toStringAsFixed(2)}',
                                  icon: Icons.account_balance_wallet,
                                  color: const Color(0xFF1A237E),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: SizedBox(
                                height: 140,
                                child: SummaryCard(
                                  title: localizations.get('today'),
                                  value: 'RM ${today.toStringAsFixed(2)}',
                                  icon: Icons.today,
                                  color: const Color(0xFF00BCD4),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 140,
                                child: SummaryCard(
                                  title: localizations.get('this_month'),
                                  value: 'RM ${month.toStringAsFixed(2)}',
                                  icon: Icons.calendar_month,
                                  color: const Color(0xFFFFA726),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: SizedBox(
                                height: 140,
                                child: SummaryCard(
                                  title: localizations.get('transactions'),
                                  value: '${donations.length}',
                                  icon: Icons.receipt_long,
                                  color: const Color(0xFFAB47BC),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          localizations.get('transactions'),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Theme.of(context).primaryColor,
                              ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const TransactionsScreen(),
                              ),
                            );
                          },
                          child: Text(localizations.get('view_all')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    recent.isEmpty
                        ? Card(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Center(
                                child: Text(
                                  localizations.get('no_transactions_yet'),
                                ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: recent.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              return TransactionTile(donation: recent[index]);
                            },
                          ),
                    const SizedBox(height: 80), // Bottom padding
                  ],
                ).animate().fadeIn(duration: 500.ms);
              },
            ),
          ),
        ),
      ],
    );
  }
}
