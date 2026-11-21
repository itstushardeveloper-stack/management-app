import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatters.dart';
import '../../core/utils/date_formatters.dart';
import '../../data/models/enquiry.dart';
import '../../data/models/follow_up.dart';
import '../../providers/app_state.dart';
import 'add_edit_enquiry_dialog.dart';
import 'convert_to_booking_dialog.dart';

class EnquiryDetailSheet extends StatefulWidget {
  final Enquiry enquiry;

  const EnquiryDetailSheet({super.key, required this.enquiry});

  @override
  State<EnquiryDetailSheet> createState() => _EnquiryDetailSheetState();
}

class _EnquiryDetailSheetState extends State<EnquiryDetailSheet> {
  late Enquiry _enquiry;
  List<FollowUp> _followUps = [];
  bool _isLoadingFollowUps = true;

  @override
  void initState() {
    super.initState();
    _enquiry = widget.enquiry;
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final state = Provider.of<AppState>(context, listen: false);
    final history = await state.enquiryRepo.getFollowUpsForEnquiry(_enquiry.id!);

    if (mounted) {
      setState(() {
        _followUps = history;
        _isLoadingFollowUps = false;
      });
    }
  }

  Future<void> _callCustomer() async {
    final uri = Uri.parse('tel:${_enquiry.phone.replaceAll(RegExp(r'[^0-9+]'), '')}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot launch phone dialer for ${_enquiry.phone}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not place call: $e')),
        );
      }
    }
  }

  void _showAddFollowUpDialog() {
    final noteController = TextEditingController();
    String newStatus = _enquiry.status;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Follow-up / Note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Discussion Notes *',
                  hintText: 'e.g. Customer called, negotiated pricing to ₹45k...',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: ['New', 'Follow-up', 'Confirmed', 'Closed'].contains(newStatus) ? newStatus : 'Follow-up',
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Update Status'),
                items: [
                  'New',
                  'Follow-up',
                  'Confirmed',
                  'Closed',
                ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => newStatus = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (noteController.text.trim().isEmpty) return;

                final state = Provider.of<AppState>(context, listen: false);
                final followUp = FollowUp(
                  enquiryId: _enquiry.id!,
                  note: noteController.text.trim(),
                  oldStatus: _enquiry.status,
                  newStatus: newStatus,
                  nextFollowUpDate: null,
                );

                await state.addFollowUpNote(followUp);
                final updated = await state.enquiryRepo.getEnquiryById(_enquiry.id!);
                if (updated != null && mounted) {
                  setState(() {
                    _enquiry = updated;
                  });
                }
                Navigator.pop(ctx);
                _loadDetails();
              },
              child: const Text('Save Note'),
            ),
          ],
        ),
      ),
    );
  }

  void _editEnquiry() async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => AddEditEnquiryDialog(enquiry: _enquiry),
    );
    if (updated == true) {
      final state = Provider.of<AppState>(context, listen: false);
      final refreshed = await state.enquiryRepo.getEnquiryById(_enquiry.id!);
      if (refreshed != null && mounted) {
        setState(() {
          _enquiry = refreshed;
        });
        _loadDetails();
      }
    }
  }

  void _convertEnquiry() async {
    final result = await showDialog(
      context: context,
      builder: (ctx) => ConvertToBookingDialog(enquiry: _enquiry),
    );
    if (result != null && mounted) {
      final state = Provider.of<AppState>(context, listen: false);
      final refreshed = await state.enquiryRepo.getEnquiryById(_enquiry.id!);
      if (refreshed != null) {
        setState(() {
          _enquiry = refreshed;
        });
        _loadDetails();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = AppColors.getStatusColor(_enquiry.status);
    final statusBgColor = AppColors.getStatusBgColor(_enquiry.status);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _enquiry.customerName,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _enquiry.status,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_enquiry.enquiryNumber} • Created ${DateFormatters.formatDateShort(_enquiry.createdAt)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit Enquiry',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: _editEnquiry,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action Bar (Call, Edit, Follow-up, Convert)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.phone),
                          label: const Text('Call'),
                          onPressed: _callCustomer,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit'),
                          onPressed: _editEnquiry,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.followUp,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.add_comment_outlined),
                          label: const Text('Add Note'),
                          onPressed: _showAddFollowUpDialog,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Important Action: Convert into Event
                  if (!_enquiry.isConverted)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.confirmed,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 1,
                        ),
                        icon: const Icon(Icons.event_available),
                        label: const Text(
                          'Convert to Confirmed Event',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _convertEnquiry,
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.confirmedLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.confirmed),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.confirmed),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Converted to Confirmed Booking! (Event ID #${_enquiry.convertedEventId ?? "Linked"})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.confirmed,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Key Details Grid
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _detailRow(Icons.phone_outlined, 'Mobile Number', _enquiry.phone),
                        if (_enquiry.email != null && _enquiry.email!.isNotEmpty)
                          _detailRow(Icons.email_outlined, 'Email', _enquiry.email!),
                        _detailRow(Icons.celebration_outlined, 'Event Type', _enquiry.eventType),
                        _detailRow(Icons.group_outlined, 'Expected Guests', '${_enquiry.guests} people'),
                        _detailRow(
                          Icons.calendar_today_outlined,
                          'Preferred Date',
                          DateFormatters.formatDate(_enquiry.preferredDate),
                        ),
                        _detailRow(Icons.access_time_outlined, 'Preferred Time', _enquiry.preferredTime),
                        _detailRow(
                          Icons.currency_rupee,
                          'Expected Budget',
                          CurrencyFormatters.format(_enquiry.expectedBudget),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notes section
                  if (_enquiry.notes != null && _enquiry.notes!.isNotEmpty) ...[
                    const Text('Requirements / Notes', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.outlineLight),
                      ),
                      child: Text(_enquiry.notes!),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Follow-up history timeline
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Follow-up & Activity History',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Note'),
                        onPressed: _showAddFollowUpDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_isLoadingFollowUps)
                    const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
                  else if (_followUps.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'No follow-up notes yet. Click "+ Add Note" to log a conversation.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _followUps.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final item = _followUps[i];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.outlineLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (item.newStatus != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.getStatusBgColor(item.newStatus!),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        item.newStatus!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.getStatusColor(item.newStatus!),
                                        ),
                                      ),
                                    ),
                                  Text(
                                    DateFormatters.formatDateShort(item.createdAt),
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(item.note, style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: highlight ? AppColors.followUp : AppColors.textSecondary),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: highlight ? AppColors.followUp : AppColors.textSecondary,
                fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: highlight ? AppColors.followUp : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

