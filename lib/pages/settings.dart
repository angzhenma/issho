import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:issho/models/button.dart';
import 'package:issho/pages/account.dart';
import 'package:issho/pages/settings/edit_account.dart';
import 'package:issho/pages/settings/edit_notis.dart';
import 'package:issho/pages/settings/support.dart';
import 'package:issho/themes/theme_notifier.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _buildTile(
            icon: Icons.person_rounded,
            label: 'Edit Account',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditAccountPage()),
            ),
          ),
          _buildTile(
            icon: Icons.notifications_rounded,
            label: 'Notification Settings',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditNotificationsPage()),
            ),
          ),
          _buildTile(
            icon: Icons.help_outline_rounded,
            label: 'Help & Support',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SupportPage()),
            ),
          ),
          SwitchListTile(
            value: isDark,
            onChanged: (val) {
              themeNotifier.setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
            },
            title: const Text('Dark Mode'),
            secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppButton(
              label: 'Sign Out',
              icon: Icons.logout_rounded,
              isExpanded: true,
              onPressed: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: LinearProgressIndicator(),)
                );
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

