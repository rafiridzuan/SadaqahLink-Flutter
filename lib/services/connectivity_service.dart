import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:sadaqahlink/utils/app_localizations.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();

  void initialize(BuildContext context) {
    _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (results.contains(ConnectivityResult.none)) {
        _showNoInternetDialog(context);
      }
    });
  }

  void _showNoInternetDialog(BuildContext context) {
    // Only show if no other dialog is open (simple check) can be complex
    // For now, using a SnackBar might be less intrusive but user asked for "message box"
    // Using AlertDialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.wifi_off, size: 48, color: Colors.red),
        content: Text(
          AppLocalizations.of(context).get('internet_error'),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Check again
              final results = await _connectivity.checkConnectivity();
              if (!results.contains(ConnectivityResult.none)) {
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: Text(
              AppLocalizations.of(context).get('done'),
            ), // Re-using done or add 'Retry'
          ),
        ],
      ),
    );
  }
}
