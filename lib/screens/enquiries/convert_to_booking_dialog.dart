import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatters.dart';
import '../../core/utils/date_formatters.dart';
import '../../data/models/enquiry.dart';
import '../../data/models/event_booking.dart';
import '../../providers/app_state.dart';

class ConvertToBookingDialog extends StatefulWidget {
  final Enquiry enquiry;

  const ConvertToBookingDialog({super.key, required this.enquiry});

  @override
  State<ConvertToBookingDialog> createState() => _ConvertToBookingDialogState();
}

class _ConvertToBookingDialogState extends State<ConvertToBookingDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _totalCostController;
  late TextEditingController _advanceController;
  late TextEditingController _notesController;

  late DateTime _eventDate;
  late String _startTime;
  late String _endTime;
  String _paymentMethod = 'UPI/Online';

  final List<String> _paymentMethods = [
    'UPI/Online',
    'Cash',
    'Bank Transfer',
    'Card',
    'Cheque',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.enquiry;
    _eventDate = e.preferredDate;
    _startTime = e.startTime ?? '10:00 AM';
    _endTime = e.endTime ?? '05:00 PM';

    _totalCostController = TextEditingController(
      text: e.expectedBudget > 0 ? e.expectedBudget.toStringAsFixed(0) : '50000',
    );
    _advanceController = TextEditingController(text: '10000');
    _notesController = TextEditingController(text: e.notes ?? '');
  }

  @override
  void dispose() {
    _totalCostController.dispose();
    _advanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      setState(() {
        _eventDate = picked;
      });
      _checkHallAvailability();
    }
  }

  void _convert() async {
    if (!_formKey.currentState!.validate()) return;

    final state = Provider.of<AppState>(context, listen: false);
    final totalCost = double.tryParse(_totalCostController.text.trim()) ?? 0.0;
    final advance = double.tryParse(_advanceController.text.trim()) ?? 0.0;
    final balance = (totalCost - advance).clamp(0.0, double.infinity);

    final eventNumber = await state.eventRepo.generateNextEventNumber();

    final eventData = EventBooking(
      eventNumber: eventNumber,
      enquiryId: widget.enquiry.id,
      customerId: widget.enquiry.customerId,
      customerName: widget.enquiry.customerName,
      phone: widget.enquiry.phone,
      email: widget.enquiry.email,
      eventType: widget.enquiry.eventType,
      guests: widget.enquiry.guests,
      eventDate: _eventDate,
      startTime: _startTime,
      endTime: _endTime,
      hallId: 1,
      hallName: 'Standard Venue',
      totalCost: totalCost,
      advancePaid: advance,
      balanceDue: balance,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      status: 'Confirmed',
    );

    try {
      final created = await state.convertEnquiryToBooking(
        enquiry: widget.enquiry,
        eventData: eventData,
        initialAdvance: advance,
        paymentMethod: _paymentMethod,
      );

      if (mounted) {
        Navigator.pop(context, created);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Enquiry converted successfully to Event #${created.eventNumber}! Now visible in Calendar.',
            ),
            backgroundColor: AppColors.confirmed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error converting: $e'), backgroundColor: AppColors.lost),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Convert Enquiry to Booking',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Enquiry: ${widget.enquiry.enquiryNumber} • ${widget.enquiry.customerName}',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Summary Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _summaryItem('Event', widget.enquiry.eventType),
                        _summaryItem('Guests', '${widget.enquiry.guests}'),
                        _summaryItem('Customer', widget.enquiry.customerName),
                        _summaryItem('Mobile', widget.enquiry.phone),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Schedule Confirmation
                  const Text(
                    'Schedule Confirmation',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _pickDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Event Date *',
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(DateFormatters.formatDate(_eventDate)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: _startTime,
                          decoration: const InputDecoration(
                            labelText: 'Start Time',
                            prefixIcon: Icon(Icons.access_time),
                          ),
                          onChanged: (v) {
                            _startTime = v;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: _endTime,
                          decoration: const InputDecoration(
                            labelText: 'End Time',
                            prefixIcon: Icon(Icons.access_time),
                          ),
                          onChanged: (v) {
                            _endTime = v;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Cost & Advance Payment
                  const Text(
                    'Financial Agreement & Advance Payment',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _totalCostController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Total Cost (₹) *',
                            prefixIcon: Icon(Icons.currency_rupee),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _advanceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Advance Paid (₹)',
                            prefixIcon: Icon(Icons.payments_outlined),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _paymentMethod,
                          decoration: const InputDecoration(
                            labelText: 'Advance Payment Mode',
                            prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                          ),
                          items: _paymentMethods
                              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _paymentMethod = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Builder(builder: (ctx) {
                          final cost = double.tryParse(_totalCostController.text) ?? 0.0;
                          final adv = double.tryParse(_advanceController.text) ?? 0.0;
                          final balance = (cost - adv).clamp(0.0, double.infinity);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.outline),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Remaining Balance Due', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                Text(
                                  CurrencyFormatters.format(balance),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.newEnquiry,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Booking Notes',
                      hintText: 'Any special terms or banquet instructions...',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.confirmed,
                        ),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Confirm & Create Event'),
                        onPressed: _isAvailable ? _convert : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

