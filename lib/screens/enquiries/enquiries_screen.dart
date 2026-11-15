import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatters.dart';
import '../../core/utils/date_formatters.dart';
import '../../data/models/enquiry.dart';
import '../../providers/app_state.dart';
import 'add_edit_enquiry_dialog.dart';
import 'enquiry_detail_sheet.dart';
import 'convert_to_booking_dialog.dart';

class EnquiriesScreen extends StatefulWidget {
  const EnquiriesScreen({super.key});

  @override
  State<EnquiriesScreen> createState() => _EnquiriesScreenState();
}

class _EnquiriesScreenState extends State<EnquiriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All';

  final List<String> _statusFilters = [
    'All',
    'New',
    'Follow-up',
    'Confirmed',
    'Closed',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final state = Provider.of<AppState>(context, listen: false);
    state.loadEnquiries(
      searchQuery: _searchController.text.trim(),
      statusFilter: _selectedStatus == 'All' ? null : _selectedStatus,
    );
  }

  void _openDetailSheet(Enquiry enquiry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.88,
        child: EnquiryDetailSheet(enquiry: enquiry),
      ),
    );
  }

  void _callCustomer(String phone) async {
    final uri = Uri.parse('tel:${phone.replaceAll(RegExp(r'[^0-9+]'), '')}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final enquiries = state.enquiries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enquiries & Leads'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => _applyFilter(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Enquiry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () async {
          final res = await showDialog(
            context: context,
            builder: (ctx) => const AddEditEnquiryDialog(),
          );
          if (res == true) {
            _applyFilter();
          }
        },
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by customer name, phone, enquiry #...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilter();
                            },
                          )
                        : null,
                    isDense: true,
                  ),
                  onChanged: (_) => _applyFilter(),
                ),
                const SizedBox(height: 10),

                // Status Filter Dropdown (replaces chips)
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Status',
                    prefixIcon: Icon(Icons.filter_list),
                    isDense: true,
                  ),
                  items: _statusFilters.map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s == 'All' ? 'All Enquiries' : s),
                  )).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedStatus = val;
                      });
                      _applyFilter();
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Enquiry List
          Expanded(
            child: enquiries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.contact_phone_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          'No enquiries found',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedStatus != 'All'
                              ? 'Try switching the "$_selectedStatus" filter'
                              : 'Tap "+ New Enquiry" to add one',
                          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: enquiries.length,
                    itemBuilder: (ctx, i) {
                      final enq = enquiries[i];
                      final statusColor = AppColors.getStatusColor(enq.status);
                      final statusBg = AppColors.getStatusBgColor(enq.status);

                      return Card(
                        child: InkWell(
                          onTap: () => _openDetailSheet(enq),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top row: Name, Enquiry # and Status Badge
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          enq.customerName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          enq.enquiryNumber,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusBg,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        enq.status,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Event & Hall Info
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Icon(Icons.celebration, size: 16, color: AppColors.textSecondary),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              '${enq.eventType} • ${enq.guests} guests',
                                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.meeting_room_outlined, size: 16, color: AppColors.textSecondary),
                                        const SizedBox(width: 6),
                                        Text(
                                          enq.preferredHallName ?? 'Any Hall',
                                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Date & Time
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${DateFormatters.formatDate(enq.preferredDate)} (${enq.preferredTime})',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Bottom row: Budget, Follow-up and Call Action
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Text('Budget: ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                        Text(
                                          CurrencyFormatters.format(enq.expectedBudget),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.phone, color: AppColors.primary, size: 20),
                                          tooltip: 'Call ${enq.phone}',
                                          onPressed: () => _callCustomer(enq.phone),
                                        ),
                                        if (!enq.isConverted)
                                          TextButton.icon(
                                            icon: const Icon(Icons.check_circle_outline, size: 16),
                                            label: const Text('Convert', style: TextStyle(fontSize: 12)),
                                            style: TextButton.styleFrom(
                                              foregroundColor: AppColors.confirmed,
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                            ),
                                            onPressed: () async {
                                              await showDialog(
                                                context: context,
                                                builder: (ctx) => ConvertToBookingDialog(enquiry: enq),
                                              );
                                              _applyFilter();
                                            },
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

