import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatters.dart';
import '../../data/database/app_database.dart';
import '../../data/database/sample_data.dart';
import '../../providers/app_state.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  bool _isBackingUp = false;

  Future<void> _exportBackup() async {
    setState(() => _isBackingUp = true);

    try {
      final db = await AppDatabase.instance.database;
      final customers = await db.query('customers');
      final halls = await db.query('halls');
      final enquiries = await db.query('enquiries');
      final followUps = await db.query('follow_ups');
      final events = await db.query('events');
      final payments = await db.query('payments');
      final expenses = await db.query('expenses');

      final backupData = {
        'version': 1,
        'exported_at': DateTime.now().toIso8601String(),
        'customers': customers,
        'halls': halls,
        'enquiries': enquiries,
        'follow_ups': followUps,
        'events': events,
        'payments': payments,
        'expenses': expenses,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      final filename = 'event_manager_backup_${DateFormatters.formatIsoDate(DateTime.now())}.json';

      await Share.share(
        jsonString,
        subject: 'Event & Venue Manager Backup - ${DateFormatters.formatDate(DateTime.now())}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup JSON exported successfully!'), backgroundColor: AppColors.confirmed),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e'), backgroundColor: AppColors.lost),
        );
      }
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Data Storage'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Database status card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.storage, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text('Local SQLite Database', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'All event records, customer CRM data, hall bookings, and payments are stored offline directly in your device SQLite database. No external cloud dependency required.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _dbCountItem('Enquiries', '${state.enquiries.length}'),
                      _dbCountItem('Events', '${state.events.length}'),
                      _dbCountItem('Customers', '${state.customers.length}'),
                      _dbCountItem('Halls', '${state.halls.length}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Backup section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Export Offline Backup', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text(
                    'Export all your data into an offline JSON backup file. You can email, share via WhatsApp, or save to Google Drive.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    icon: _isBackingUp
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.download),
                    label: const Text('Create & Share Full Backup'),
                    onPressed: _isBackingUp ? null : _exportBackup,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dbCountItem(String label, String count) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

