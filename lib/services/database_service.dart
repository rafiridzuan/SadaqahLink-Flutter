import 'package:firebase_database/firebase_database.dart';
import 'package:sadaqahlink/models/donation_model.dart';
import 'package:sadaqahlink/services/notification_service.dart';

class DatabaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Get donations stream
  Stream<List<Donation>> getDonations() {
    return _db.child('transactions').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];

      try {
        if (data is Map) {
          return data.entries
              .map((e) {
                final val = e.value;
                if (val is Map) {
                  return Donation.fromMap(val, e.key.toString());
                }
                return null;
              })
              .whereType<Donation>()
              .toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        }
        return [];
      } catch (e) {
        // print('Error parsing donations: $e');
        return [];
      }
    });
  }

  // Get total donations
  Future<double> getTotalDonations() async {
    final snapshot = await _db.child('transactions').get();
    if (!snapshot.exists) return 0.0;

    final data = snapshot.value;
    double total = 0.0;

    if (data is Map) {
      for (var val in data.values) {
        if (val is Map) {
          // value is in cents
          total += ((val['value'] ?? 0) as num).toDouble() / 100.0;
        }
      }
    }

    return total;
  }

  // Listen for new transactions and trigger notifications
  void listenForNotifications() {
    // Listen for new transactions
    _db.child('transactions').limitToLast(1).onChildAdded.listen((event) {
      final data = event.snapshot.value;
      if (data is Map) {
        final double amount = ((data['value'] ?? 0) as num).toDouble() / 100.0;
        final int amountInt = amount.toInt();

        // Check if the transaction is recent (within last 10 seconds) to avoid spamming on startup
        // Note: 'tarikh' is millis
        final int timestamp = (data['tarikh'] ?? data['timestamp'] ?? 0) as int;
        final int now = DateTime.now().millisecondsSinceEpoch;
        if (now - timestamp < 10000) {
          _sendDonationNotification(amountInt);
        }
      }
    });

    // Listen for device status
    _db.child('device_status/online').onValue.listen((event) {
      final isOnline = event.snapshot.value as bool? ?? false;
      if (isOnline) {
        NotificationService().showNotification(
          id: 999,
          title: 'Tabung Active',
          body: 'Your surau\'s tabung is now active!',
        );
      }
    });
  }

  void _sendDonationNotification(int amount) {
    String body = '';
    switch (amount) {
      case 1:
        body = 'Ding dong! Your surau\'s tabung has received RM1';
        break;
      case 5:
        body = 'Ding dong! Your surau\'s tabung has received RM5';
        break;
      case 10:
        body = 'Alhamdulillah! Your surau\'s tabung has received RM10';
        break;
      case 20:
        body = 'Alhamdulillah! Your surau\'s tabung has received RM20';
        break;
      case 50:
        body = 'Subhanallah! Your surau\'s tabung has received RM50';
        break;
      case 100:
        body = 'MasyaAllah! Your surau\'s tabung has received RM100';
        break;
      default:
        body = 'Ding dong! Your surau\'s tabung has received RM$amount';
    }

    NotificationService().showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'New Donation Received',
      body: body,
    );
  }
}
