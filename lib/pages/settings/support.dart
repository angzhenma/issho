import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:issho/models/button.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  final String _supportFormUrl = 'https://forms.gle/ESTFr3EVd4ztDdmJA';

  Future<void> _openSupportForm() async {
    final Uri url = Uri.parse(_supportFormUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $_supportFormUrl');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Need help or have feedback?',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'We’d love to hear from you. Tap the button below to contact Issho Support.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Contact Support',
              icon: Icons.support_agent_rounded,
              onPressed: _openSupportForm,
              isExpanded: true,
            ),
          ],
        ),
      ),
    );
  }
}