import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sadaqahlink/models/donation_model.dart';

class TransactionTile extends StatelessWidget {
  final Donation donation;

  const TransactionTile({super.key, required this.donation});

  @override
  Widget build(BuildContext context) {
    final isCash = donation.method.toLowerCase() == 'cash';
    final color = isCash ? const Color(0xFF00BCD4) : const Color(0xFF1A237E);

    return Card(
      elevation: 0,
      color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Big Leading Section
            Container(
              width: 80,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isCash ? Icons.payments_outlined : Icons.qr_code_2,
                    color: color,
                    size: 32,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    donation.method.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Title & Subtitle Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '+ RM ${donation.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.green[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat(
                      'dd MMM yyyy, hh:mm a',
                    ).format(donation.timestamp),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
