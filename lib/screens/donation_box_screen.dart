import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:sadaqahlink/widgets/background_wrapper.dart';
import 'package:sadaqahlink/widgets/blurred_app_bar.dart';

import 'package:sadaqahlink/utils/app_localizations.dart';

class DonationBoxScreen extends StatelessWidget {
  const DonationBoxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return BackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BlurredAppBar(
          title: Text(localizations.get('donation_box_wifi')),
        ),
        body: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_tethering,
                size: 100,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                localizations.get('connect_to_box'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildInstructionStep(
                context,
                '1',
                localizations.get('instruction_1'),
              ),
              _buildInstructionStep(
                context,
                '2',
                localizations.get('instruction_2'),
              ),
              _buildInstructionStep(
                context,
                '3',
                localizations.get('instruction_3'),
              ),
              _buildInstructionStep(
                context,
                '4',
                localizations.get('instruction_4'),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    AppSettings.openAppSettings(type: AppSettingsType.wifi);
                  },
                  icon: const Icon(Icons.settings_remote),
                  label: Text(
                    localizations.get('open_wifi'),
                    style: const TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionStep(
    BuildContext context,
    String number,
    String text,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
