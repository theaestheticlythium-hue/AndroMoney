import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/glass_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: LiquidGlassBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
          children: [
            _sectionTitle('GENERAL'),
            _settingsCard(
              icon: Icons.currency_rupee,
              title: 'Currency',
              subtitle: 'Indian Rupee (₹)',
              trailing: const Icon(
                Icons.check_circle,
                color: AppTheme.primary,
                size: 20,
              ),
            ),
            _settingsCard(
              icon: Icons.dark_mode_outlined,
              title: 'Appearance',
              subtitle: 'Dark liquid glass theme',
              trailing: const Icon(
                Icons.check_circle,
                color: AppTheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(height: 22),
            _sectionTitle('DATA & STORAGE'),
            _settingsCard(
              icon: Icons.storage_outlined,
              title: 'Storage location',
              subtitle: 'Data is stored locally on this device',
            ),
            _settingsCard(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Ledger',
              subtitle: 'Income, expenses and fund transfers are tracked separately',
            ),
            const SizedBox(height: 22),
            _sectionTitle('ABOUT'),
            _settingsCard(
              icon: Icons.account_balance_outlined,
              title: 'AndroMoney',
              subtitle: 'Personal Finance & Ledger',
            ),
            _settingsCard(
              icon: Icons.info_outline,
              title: 'App information',
              subtitle: 'Version 1.0.0',
            ),
            const SizedBox(height: 28),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: AppTheme.primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'AndroMoney',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your money with clarity.',
                    style: TextStyle(
                      color: AppTheme.muted,
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

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.primary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.3,
        ),
      ),
    );
  }

  Widget _settingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 5,
          ),
          leading: Icon(icon, color: AppTheme.primary, size: 22),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle,
              style: TextStyle(
                color: AppTheme.muted,
                fontSize: 12,
              ),
            ),
          ),
          trailing: trailing,
        ),
      ),
    );
  }
}
