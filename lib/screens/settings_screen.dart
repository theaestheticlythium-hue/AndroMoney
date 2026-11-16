import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const Color _background = Color(0xFF080D12);
  static const Color _card = Color(0xFF111B22);
  static const Color _accent = Color(0xFF00E676);
  static const Color _muted = Color(0xFF8A969E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('GENERAL'),
          _settingsCard(
            icon: Icons.currency_rupee,
            title: 'Currency',
            subtitle: 'Indian Rupee (₹)',
            trailing: const Icon(
              Icons.check_circle,
              color: _accent,
              size: 20,
            ),
          ),
          _settingsCard(
            icon: Icons.dark_mode_outlined,
            title: 'Appearance',
            subtitle: 'Dark theme',
            trailing: const Icon(
              Icons.check_circle,
              color: _accent,
              size: 20,
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('DATA & STORAGE'),
          _settingsCard(
            icon: Icons.storage_outlined,
            title: 'Storage location',
            subtitle: 'Data is stored locally on this device',
          ),
          _settingsCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Accounting method',
            subtitle: 'Double-entry bookkeeping',
          ),
          const SizedBox(height: 24),
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
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: const [
                Icon(
                  Icons.account_balance_wallet,
                  color: _accent,
                  size: 32,
                ),
                SizedBox(height: 8),
                Text(
                  'AndroMoney',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Manage your money with clarity.',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: _accent,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 5,
        ),
        leading: Icon(icon, color: _accent, size: 22),
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
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
            ),
          ),
        ),
        trailing: trailing,
      ),
    );
  }
}
