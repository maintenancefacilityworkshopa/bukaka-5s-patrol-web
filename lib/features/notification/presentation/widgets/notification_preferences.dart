import 'package:flutter/material.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  bool _pushNotification = true;
  bool _emailNotification = false;
  bool _scheduleReminder = true;

  static const primaryBlue = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notification Preferences',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSwitchTile(
              title: 'Push Notification',
              subtitle: 'Dapatkan pemberitahuan langsung di perangkat Anda',
              value: _pushNotification,
              onChanged: (val) => setState(() => _pushNotification = val),
            ),
            const SizedBox(height: 12),
            _buildSwitchTile(
              title: 'Email Notification',
              subtitle: 'Kirimkan ringkasan hasil patroli via email',
              value: _emailNotification,
              onChanged: (val) => setState(() => _emailNotification = val),
            ),
            const SizedBox(height: 12),
            _buildSwitchTile(
              title: 'Pengingat Schedule Patrol',
              subtitle: 'Notifikasi pengingat sebelum jadwal patrol 5S dimulai',
              value: _scheduleReminder,
              onChanged: (val) => setState(() => _scheduleReminder = val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: primaryBlue,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}