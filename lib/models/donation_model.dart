class Donation {
  final String id;
  final double amount;
  final String method; // 'cash' | 'qrpay'
  final DateTime timestamp;
  final String source; // 'esp32'

  Donation({
    required this.id,
    required this.amount,
    required this.method,
    required this.timestamp,
    required this.source,
  });

  factory Donation.fromMap(Map<dynamic, dynamic> map, String id) {
    // Handle timestamp from RTDB (tarikh is millis)
    DateTime parseTimestamp(dynamic val) {
      if (val is int) {
        return DateTime.fromMillisecondsSinceEpoch(val);
      } else if (val is String) {
        return DateTime.parse(val);
      }
      return DateTime.now(); // Fallback
    }

    return Donation(
      id: id,
      amount: (map['value'] != null)
          ? (map['value'] as num).toDouble() / 100.0
          : (map['amount'] ?? 0).toDouble(), // Fallback to old key if needed
      method: map['method'] ?? 'cash',
      timestamp: parseTimestamp(map['tarikh'] ?? map['timestamp']),
      source: map['source'] ?? 'esp32',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'method': method,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'source': source,
    };
  }
}
