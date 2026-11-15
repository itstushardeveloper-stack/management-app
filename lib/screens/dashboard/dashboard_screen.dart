import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatters.dart';
import '../../core/utils/date_formatters.dart';
import '../../providers/app_state.dart';
import '../enquiries/add_edit_enquiry_dialog.dart';
import '../enquiries/enquiry_detail_sheet.dart';
import '../events/add_edit_event_dialog.dart';
import '../calendar/event_detail_popup.dart';
import '../finance/add_payment_dialog.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
    final reminders = state.followUpReminders;
    final todayEvents = state.todayEvents;
    final upcomingEvents = state.events.where((e) {
      final now = DateTime.now();
      return e.eventDate.isAfter(now.subtract(const Duration(days: 1))) &&
          e.status != 'Cancelled';
    }).take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event & Venue Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => state.refreshAll(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => state.refreshAll(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. KPI Stats Grid
              LayoutBuilder(
                builder: (ctx, constraints) {
                  final isWide = constraints.maxWidth > 600;
                  return GridView.count(
                    crossAxisCount: isWide ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: isWide ? 1.6 : 1.35,
                    children: [
                      _kpiCard(
                        title: 'Total Revenue',
                        value: CurrencyFormatters.format(state.totalIncome),
                        subtitle: 'Received payments',
                        icon: Icons.account_balance_wallet,
                        color: AppColors.confirmed,
                        bgColor: AppColors.confirmedLight,
                      ),
                      _kpiCard(
                        title: 'Pending Balances',
                        value: CurrencyFormatters.format(state.totalBalancePending),
                        subtitle: 'To be collected',
                        icon: Icons.pending_actions,
                        color: AppColors.newEnquiry,
                        bgColor: AppColors.newEnquiryLight,
                      ),
                      _kpiCard(
                        title: 'Net Profit',
                        value: CurrencyFormatters.format(state.netProfit),
                        subtitle: 'After expenses',
                        icon: Icons.trending_up,
                        color: AppColors.primary,
                        bgColor: AppColors.primaryLight,
                      ),
                      _kpiCard(
                        title: 'Active Leads',
                        value: '${state.enquiries.where((e) => !e.isConverted && e.status != 'Lost' && e.status != 'Cancelled').length}',
                        subtitle: '${state.events.where((e) => e.status == 'Confirmed').length} Confirmed events',
                        icon: Icons.contact_phone,
                        color: AppColors.quotationSent,
                        bgColor: AppColors.quotationSentLight,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // 2. Quick Action Bar
              const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _actionChip(
                      icon: Icons.person_add_alt_1,
                      label: '+ New Enquiry',
                      color: AppColors.primary,
                      onTap: () => showDialog(context: context, builder: (ctx) => const AddEditEnquiryDialog()),
                    ),
                    const SizedBox(width: 8),
                    _actionChip(
                      icon: Icons.event_available,
                      label: '+ Book Event',
                      color: AppColors.confirmed,
                      onTap: () => showDialog(context: context, builder: (ctx) => const AddEditEventDialog()),
                    ),
                    const SizedBox(width: 8),
                    _actionChip(
                      icon: Icons.payment,
                      label: 'Record Payment',
                      color: AppColors.followUp,
                      onTap: () => showDialog(context: context, builder: (ctx) => const AddPaymentDialog()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. Follow-up Reminders (High Priority CRM Section)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.alarm_on, color: AppColors.followUp, size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        'Follow-up Reminders Due Today',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (reminders.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.followUpLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.followUp),
                      ),
                      child: Text(
                        '${reminders.length} Due',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.followUp),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              if (reminders.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.outlineLight),
                  ),
                  child: const Center(
                    child: Text(
                      'No pending follow-ups scheduled for today. Great job!',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                )
              else
                ...reminders.map((enq) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (ctx) => FractionallySizedBox(
                              heightFactor: 0.88,
                              child: EnquiryDetailSheet(enquiry: enq),
                            ),
                          );
                        },
                        title: Text(
                          '${enq.customerName} (${enq.eventType})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Pref: ${DateFormatters.formatDate(enq.preferredDate)} • Budget: ${CurrencyFormatters.format(enq.expectedBudget)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.phone, color: AppColors.primary),
                              tooltip: 'Call Customer',
                              onPressed: () => _callCustomer(enq.phone),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    )),
              const SizedBox(height: 24),

              // 4. Today's Events
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.today, color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        "Today's Venue Schedule",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Text(
                    DateFormatters.formatDayDate(DateTime.now()),
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (todayEvents.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.outlineLight),
                  ),
                  child: const Center(
                    child: Text(
                      'No events booked for today. All halls available!',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                )
              else
                ...todayEvents.map((evt) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => EventDetailPopup(event: evt),
                          );
                        },
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.confirmedLight,
                          child: Icon(Icons.celebration, color: AppColors.confirmed),
                        ),
                        title: Text(evt.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${evt.eventType} • ${evt.hallName} • ${evt.startTime} - ${evt.endTime}'),
                        trailing: Text(CurrencyFormatters.format(evt.totalCost), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    )),
              const SizedBox(height: 24),

              // 5. Upcoming Bookings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Upcoming Confirmed Events', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => state.setTabIndex(2), // Jump to Calendar tab
                    child: const Text('View Full Calendar >'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ...upcomingEvents.map((evt) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => EventDetailPopup(event: evt),
                        );
                      },
                      leading: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${evt.eventDate.day}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                          Text(DateFormatters.formatMonthYear(evt.eventDate).split(' ')[0].substring(0, 3).toUpperCase(), style: const TextStyle(fontSize: 10)),
                        ],
                      ),
                      title: Text('${evt.customerName} - ${evt.eventType}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${evt.hallName.split('(')[0]} • ${evt.startTime} - ${evt.endTime} • ${evt.guests} guests'),
                      trailing: Text(CurrencyFormatters.format(evt.totalCost), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  )),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              CircleAvatar(backgroundColor: bgColor, radius: 14, child: Icon(icon, size: 16, color: color)),
            ],
          ),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _actionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

