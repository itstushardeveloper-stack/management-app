import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatters.dart';
import '../../core/utils/date_formatters.dart';
import '../../data/models/event_booking.dart';
import '../../providers/app_state.dart';

class AddEditEventDialog extends StatefulWidget {
  final EventBooking? event;
  final DateTime? initialDate;

  const AddEditEventDialog({super.key, this.event, this.initialDate});

  @override
  State<AddEditEventDialog> createState() => _AddEditEventDialogState();
}

class _AddEditEventDialogState extends State<AddEditEventDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _eventTypeController;
  late TextEditingController _guestsController;
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;
  late TextEditingController _totalCostController;
  late TextEditingController _advanceController;
  late TextEditingController _notesController;

  late DateTime _eventDate;
  String _status = 'Confirmed';
  String _eventNumber = '';

  final List<String> _statusOptions = ['Confirmed', 'In-Progress', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    final ev = widget.event;
    _nameController = TextEditingController(text: ev?.customerName ?? '');
    _phoneController = TextEditingController(text: ev?.phone ?? '');
    _emailController = TextEditingController(text: ev?.email ?? '');
    _eventTypeController = TextEditingController(text: ev?.eventType ?? 'Wedding Reception');
    _guestsController = TextEditingController(text: ev?.guests != null ? '${ev!.guests}' : '300');
    _startTimeController = TextEditingController(text: ev?.startTime ?? '10:00 AM');
    _endTimeController = TextEditingController(text: ev?.endTime ?? '05:00 PM');
    _totalCostController = TextEditingController(
      text: ev?.totalCost != null ? ev!.totalCost.toStringAsFixed(0) : '50000',
    );
    _advanceController = TextEditingController(
      text: ev?.advancePaid != null ? ev!.advancePaid.toStringAsFixed(0) : '15000',
    );
    _notesController = TextEditingController(text: ev?.notes ?? '');

    _eventDate = ev?.eventDate ?? widget.initialDate ?? DateTime.now().add(const Duration(days: 3));
    _status = ev?.status ?? 'Confirmed';
    _eventNumber = ev?.eventNumber ?? '';

    if (ev == null) {
      _fetchNextEventNumber();
    }
  }

  Future<void> _fetchNextEventNumber() async {
    final state = Provider.of<AppState>(context, listen: false);
    final num = await state.eventRepo.generateNextEventNumber();
    if (mounted) {
      setState(() {
        _eventNumber = num;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _eventTypeController.dispose();
    _guestsController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
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
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final state = Provider.of<AppState>(context, listen: false);
    final totalCost = double.tryParse(_totalCostController.text.trim()) ?? 0.0;
    final advance = double.tryParse(_advanceController.text.trim()) ?? 0.0;
    final balance = (totalCost - advance).clamp(0.0, double.infinity);
    final guests = int.tryParse(_guestsController.text.trim()) ?? 100;

    final event = EventBooking(
      id: widget.event?.id,
      eventNumber: _eventNumber.isNotEmpty ? _eventNumber : 'EVT-001',
      enquiryId: widget.event?.enquiryId,
      customerId: widget.event?.customerId,
      customerName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      eventType: _eventTypeController.text.trim(),
      guests: guests,
      eventDate: _eventDate,
      startTime: _startTimeController.text.trim(),
      endTime: _endTimeController.text.trim(),
      hallId: widget.event?.hallId ?? 1,
      hallName: widget.event?.hallName ?? 'Standard Venue',
      totalCost: totalCost,
      advancePaid: advance,
      balanceDue: balance,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      status: _status,
      createdAt: widget.event?.createdAt,
    );

    await state.saveEvent(event);
    if (mounted) {
      Navigator.pop(context, true);
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
                          Text(
                            widget.event == null ? 'Schedule Confirmed Event' : 'Edit Event Booking',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          if (_eventNumber.isNotEmpty)
                            Text(
                              _eventNumber,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Customer Details
                  const Text('Customer Contact', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Customer Name *', prefixIcon: Icon(Icons.person)),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Mobile Number *', prefixIcon: Icon(Icons.phone)),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Event Details
                  const Text('Event Schedule', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _eventTypeController,
                          decoration: const InputDecoration(labelText: 'Event Type *', prefixIcon: Icon(Icons.celebration)),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _guestsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Guests *', prefixIcon: Icon(Icons.group)),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _pickDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Date *', prefixIcon: Icon(Icons.calendar_today)),
                            child: Text(DateFormatters.formatDate(_eventDate)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _startTimeController,
                          decoration: const InputDecoration(labelText: 'Start Time', prefixIcon: Icon(Icons.access_time)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _endTimeController,
                          decoration: const InputDecoration(labelText: 'End Time', prefixIcon: Icon(Icons.access_time)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Financials
                  const Text('Payment & Balance', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _totalCostController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Total Cost (₹) *', prefixIcon: Icon(Icons.currency_rupee)),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _advanceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Advance Paid (₹)', prefixIcon: Icon(Icons.payment)),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Builder(builder: (ctx) {
                    final total = double.tryParse(_totalCostController.text) ?? 0.0;
                    final adv = double.tryParse(_advanceController.text) ?? 0.0;
                    final bal = (total - adv).clamp(0.0, double.infinity);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Remaining Balance Due:'),
                          Text(
                            CurrencyFormatters.format(bal),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.newEnquiry),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(labelText: 'Booking Status', prefixIcon: Icon(Icons.flag_outlined)),
                    items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _status = v);
                    },
                  ),
                  const SizedBox(height: 10),

                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Special Notes / Instructions'),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: Text(widget.event == null ? 'Schedule Event' : 'Save Changes'),
                        onPressed: _save,
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
}

