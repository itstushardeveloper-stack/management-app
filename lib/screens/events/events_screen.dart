import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatters.dart';
import '../../core/utils/date_formatters.dart';
import '../../data/models/event_booking.dart';
import '../../providers/app_state.dart';
import '../calendar/event_detail_popup.dart';
import 'add_edit_event_dialog.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All';

  final List<String> _statusFilters = ['All', 'Confirmed', 'In-Progress', 'Completed', 'Cancelled'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final state = Provider.of<AppState>(context, listen: false);
    state.loadEvents(
      searchQuery: _searchController.text.trim(),
      statusFilter: _selectedStatus == 'All' ? null : _selectedStatus,
    );
  }

  void _openEventDetail(EventBooking event) {
    showDialog(
      context: context,
      builder: (ctx) => EventDetailPopup(event: event),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final events = state.events;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmed Bookings'),
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
        label: const Text('New Booking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () async {
          final res = await showDialog(
            context: context,
            builder: (ctx) => const AddEditEventDialog(),
          );
          if (res == true) _applyFilter();
        },
      ),
      body: Column(
        children: [
          // Filter Toolbar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by customer, phone, event #, type...',
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

                Row(
                  children: [
                    // Status Filter
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _statusFilters.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 6),
                          itemBuilder: (ctx, i) {
                            final s = _statusFilters[i];
                            final isSel = _selectedStatus == s;
                            return ChoiceChip(
                              label: Text(s),
                              selected: isSel,
                              selectedColor: AppColors.primaryLight,
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                color: isSel ? AppColors.primary : AppColors.textSecondary,
                              ),
                              onSelected: (val) {
                                if (val) {
                                  setState(() => _selectedStatus = s);
                                  _applyFilter();
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Events List
          Expanded(
            child: events.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.event_available, size: 64, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        const Text('No bookings match your filter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _selectedStatus = 'All';
                            });
                            _applyFilter();
                          },
                          child: const Text('Clear Filters'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: events.length,
                    itemBuilder: (ctx, i) {
                      final ev = events[i];
                      final statusColor = AppColors.getStatusColor(ev.status);
                      final statusBg = AppColors.getStatusBgColor(ev.status);

                      return Card(
                        child: InkWell(
                          onTap: () => _openEventDetail(ev),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(ev.customerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                        Text(
                                          '${ev.eventNumber} • ${ev.phone}',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                                      child: Text(
                                        ev.status,
                                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Icon(Icons.celebration, size: 16, color: AppColors.textSecondary),
                                          const SizedBox(width: 6),
                                          Flexible(child: Text('${ev.eventType} (${ev.guests} guests)', overflow: TextOverflow.ellipsis)),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const SizedBox.shrink(),
                                        const SizedBox(width: 6),
                                        const SizedBox.shrink(),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Text('${DateFormatters.formatDayDate(ev.eventDate)} • ${ev.startTime} - ${ev.endTime}', style: const TextStyle(fontWeight: FontWeight.w500)),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(CurrencyFormatters.format(ev.totalCost), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 8),
                                        if (ev.balanceDue > 0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: AppColors.newEnquiryLight, borderRadius: BorderRadius.circular(4)),
                                            child: Text('Due: ${CurrencyFormatters.format(ev.balanceDue)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.newEnquiry)),
                                          )
                                        else
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: AppColors.confirmedLight, borderRadius: BorderRadius.circular(4)),
                                            child: const Text('Fully Paid', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.confirmed)),
                                          ),
                                      ],
                                    ),
                                    const Text('View details >', style: TextStyle(fontSize: 12, color: AppColors.primary)),
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

