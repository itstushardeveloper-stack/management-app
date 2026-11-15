import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatters.dart';
import '../../core/utils/date_formatters.dart';
import '../../data/models/event_booking.dart';
import '../../data/models/payment.dart';
import '../../providers/app_state.dart';
import '../events/add_edit_event_dialog.dart';
import '../finance/add_payment_dialog.dart';

class EventDetailPopup extends StatefulWidget {
  final EventBooking event;

  const EventDetailPopup({super.key, required this.event});

  @override
  State<EventDetailPopup> createState() => _EventDetailPopupState();
}

class _EventDetailPopupState extends State<EventDetailPopup> {
  late EventBooking _event;
  List<Payment> _payments = [];
  bool _isLoadingPayments = true;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    final state = Provider.of<AppState>(context, listen: false);
    final list = await state.paymentRepo.getPaymentsForEvent(_event.id!);
    if (mounted) {
      setState(() {
        _payments = list;
        _isLoadingPayments = false;
      });
    }
  }

  Future<void> _callCustomer() async {
    final uri = Uri.parse('tel:${_event.phone.replaceAll(RegExp(r'[^0-9+]'), '')}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  void _editEvent() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AddEditEventDialog(event: _event),
    );
    if (res == true) {
      final state = Provider.of<AppState>(context, listen: false);
      final refreshed = await state.eventRepo.getEventById(_event.id!);
      if (refreshed != null && mounted) {
        setState(() {
          _event = refreshed;
        });
        _loadPayments();
      }
    }
  }

  void _recordPayment() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AddPaymentDialog(event: _event),
    );
    if (res == true) {
      final state = Provider.of<AppState>(context, listen: false);
      final refreshed = await state.eventRepo.getEventById(_event.id!);
      if (refreshed != null && mounted) {
        setState(() {
          _event = refreshed;
        });
        _loadPayments();
      }
    }
  }

  void _cancelEvent() async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Booking?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to cancel ${_event.eventNumber} (${_event.customerName})? This will release the hall reservation.'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for cancellation',
                hintText: 'e.g. Client requested postponement...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Booking'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.lost),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel Booking'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final state = Provider.of<AppState>(context, listen: false);
      await state.cancelEvent(_event.id!, reason: reasonController.text.trim());
      final refreshed = await state.eventRepo.getEventById(_event.id!);
      if (refreshed != null && mounted) {
        setState(() {
          _event = refreshed;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking marked as Cancelled.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = AppColors.getStatusColor(_event.status);
    final statusBg = AppColors.getStatusBgColor(_event.status);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _event.eventNumber,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _event.status,
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
                          _event.customerName,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Edit Event',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: _editEvent,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 20),

                // Key Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _row(Icons.celebration, 'Event Type', _event.eventType),
                      _row(Icons.group, 'Guest Count', '${_event.guests} Guests'),
                      _row(
                        Icons.calendar_today,
                        'Event Date',
                        DateFormatters.formatDayDate(_event.eventDate),
                      ),
                      _row(Icons.access_time, 'Schedule Time', '${_event.startTime} – ${_event.endTime}'),
                      _row(Icons.meeting_room, 'Hall / Venue', _event.hallName),
                      _row(Icons.phone, 'Customer Mobile', _event.phone),
                      if (_event.email != null && _event.email!.isNotEmpty)
                        _row(Icons.email, 'Email Address', _event.email!),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Financial Overview Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.outlineLight),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _financeColumn('Total Cost', CurrencyFormatters.format(_event.totalCost), AppColors.textPrimary),
                          _financeColumn('Advance Paid', CurrencyFormatters.format(_event.advancePaid), AppColors.confirmed),
                          _financeColumn(
                            'Balance Due',
                            CurrencyFormatters.format(_event.balanceDue),
                            _event.balanceDue > 0 ? AppColors.newEnquiry : AppColors.confirmed,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.confirmed,
                                side: const BorderSide(color: AppColors.confirmed),
                              ),
                              icon: const Icon(Icons.payment, size: 18),
                              label: const Text('Record Payment'),
                              onPressed: _event.balanceDue > 0 ? _recordPayment : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Event Notes
                if (_event.notes != null && _event.notes!.isNotEmpty) ...[
                  const Text('Booking Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_event.notes!, style: const TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(height: 16),
                ],

                // Payment History Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Payment History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    if (_event.balanceDue > 0)
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Payment', style: TextStyle(fontSize: 12)),
                        onPressed: _recordPayment,
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                if (_isLoadingPayments)
                  const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                else if (_payments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('No payment transactions recorded yet.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _payments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (ctx, i) {
                      final p = _payments[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${p.paymentType} (${p.paymentMethod})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                Text(DateFormatters.formatDateShort(p.paymentDate), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                            Text(CurrencyFormatters.format(p.amount), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.confirmed)),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 24),

                // Bottom Action Bar: Call, Payment, Cancel
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.phone),
                        label: const Text('Call'),
                        onPressed: _callCustomer,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_event.status != 'Cancelled')
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.lost,
                            side: const BorderSide(color: AppColors.lost),
                          ),
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Cancel Booking'),
                          onPressed: _cancelEvent,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _financeColumn(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

