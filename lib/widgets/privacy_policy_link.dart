import 'package:bike_setup_tracker/utils/translations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';

class PrivacyPolicyLink extends StatelessWidget {
  const PrivacyPolicyLink({super.key, required this.languageCode});

  final String languageCode;

  @override
  Widget build(BuildContext context) {
    var uri = Uri.parse(
      'https://samuel-schmuecker.github.io/bike_setup_tracker/privacy.html',
    );
    if (kIsWeb) {
      final current = Uri.base;
      // Keep the deployment folder, including /dev, and omit OAuth parameters.
      final path = current.path;
      final directory = path.endsWith('/') || path.endsWith('.html')
          ? path
          : '$path/';
      uri = current
          .replace(path: directory, query: '', fragment: '')
          .resolve('privacy.html');
    }
    return Link(
      uri: uri,
      target: LinkTarget.blank,
      builder: (context, followLink) => TextButton.icon(
        onPressed: followLink,
        icon: const Icon(Icons.privacy_tip_outlined),
        label: Text(Translations.get(languageCode, 'privacyPolicy')),
      ),
    );
  }
}
