import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatters.dart';
import '../../data/models/enquiry.dart';
import '../../data/models/hall.dart';
import '../../providers/app_state.dart';

class AddEditEnquiryDialog extends StatefulWidget {
  final Enquiry? enquiry;

  const AddEditEnquiryDialog({super.key, this.enquiry});

  @override
  State<AddEditEnquiryDialog> createState() => _AddEditEnquiryDialogState();
}

class _AddEditEnquiryDialogState extends State<AddEditEnquiryDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _eventTypeController;
  late TextEditingController _guestsController;
  late TextEditingController _preferredTimeController;
  late TextEditingController _budgetController;
  late TextEditingController _notesController;

  DateTime _preferredDate = DateTime.now().add(const Duration(days: 7));
  DateTime? _followUpDate;
  int? _selectedHallId;
  String? _selectedHallName;
  String _status = 'New';
  String _generatedNumber = '';

  final List<String> _statusOptions = [
    'New',
    'Follow-up',
    'Confirmed',
    'Closed',
  ];

  final List<String> _commonEventTypes = [
    'Wedding Reception',
    'Wedding Ceremony',
    'Engagement',
    'Birthday Party',
    'Gathering',
    'Corporate Seminar',
    'Annual Conference',
    'Exhibition',
    'Baby Shower',
    'Anniversary',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.enquiry;
    _nameController = TextEditingController(text: e?.customerName ?? '');
    _phoneController = TextEditingController(text: e?.phone ?? '');
    _emailController = TextEditingController(text: e?.email ?? '');
    _eventTypeController = TextEditingController(text: e?.eventType ?? 'Gathering');
    _guestsController = TextEditingController(text: e?.guests != null ? '${e!.guests}' : '200');
    _preferredTimeController = TextEditingController(text: e?.preferredTime ?? '10:00 AM – 5:00 PM');
    _budgetController = TextEditingController(
      text: e?.expectedBudget != null ? e!.expectedBudget.toStringAsFixed(0) : '50000',
    );
    _notesController = TextEditingController(text: e?.notes ?? '');

    if (e != null) {
      _preferredDate = e.preferredDate;
      _selectedHallId = e.preferredHallId;
      _selectedHallName = e.preferredHallName;
      _status = e.status;
      _generatedNumber = e.enquiryNumber;
    } else {
      _fetchNextNumber();
    }
  }

  Future<void> _fetchNextNumber() async {
    final state = Provider.of<AppState>(context, listen: false);
    final num = await state.enquiryRepo.generateNextEnquiryNumber();
    if (mounted) {
      setState(() {
        _generatedNumber = num;
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
    _preferredTimeController.dispose();
    _budgetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _preferredDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      setState(() {
        _preferredDate = picked;
      });
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final state = Provider.of<AppState>(context, listen: false);
    final guests = int.tryParse(_guestsController.text.trim()) ?? 100;
    final budget = double.tryParse(_budgetController.text.trim()) ?? 0.0;

    final enquiry = Enquiry(
      id: widget.enquiry?.id,
      enquiryNumber: _generatedNumber.isNotEmpty ? _generatedNumber : 'ENQ-001',
      customerId: widget.enquiry?.customerId,
      customerName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      eventType: _eventTypeController.text.trim(),
      guests: guests,
      preferredDate: _preferredDate,
      preferredTime: _preferredTimeController.text.trim(),
      preferredHallId: _selectedHallId,
      preferredHallName: _selectedHallName,
      expectedBudget: budget,
      followUpDate: null,
      status: _status,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      convertedEventId: widget.enquiry?.convertedEventId,
      createdAt: widget.enquiry?.createdAt,
    );

    await state.saveEnquiry(enquiry);
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final halls = Provider.of<AppState>(context).halls;

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
                            widget.enquiry == null ? 'New Customer Enquiry' : 'Edit Enquiry',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          if (_generatedNumber.isNotEmpty)
                            Text(
                              _generatedNumber,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
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
                  const Divider(height: 24),

                  // Customer Details Section
                  const Text(
                    'Customer Information',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Customer Name *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Customer name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Mobile Number *',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Phone is required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email (Optional)',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Event Requirements
                  const Text(
                    'Event Requirements',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _eventTypeController,
                          decoration: InputDecoration(
                            labelText: 'Event Type *',
                            prefixIcon: const Icon(Icons.celebration_outlined),
                            suffixIcon: PopupMenuButton<String>(
                              icon: const Icon(Icons.arrow_drop_down),
                              onSelected: (val) {
                                _eventTypeController.text = val;
                              },
                              itemBuilder: (ctx) => _commonEventTypes
                                  .map((type) => PopupMenuItem(value: type, child: Text(type)))
                                  .toList(),
                            ),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Event type is required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _guestsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Guests *',
                            prefixIcon: Icon(Icons.group_outlined),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Date & Time
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDate(),
                          borderRadius: BorderRadius.circular(10),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Preferred Date *',
                              prefixIcon: Icon(Icons.calendar_today_outlined),
                            ),
                            child: Text(DateFormatters.formatDate(_preferredDate)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _preferredTimeController,
                          decoration: const InputDecoration(
                            labelText: 'Preferred Time *',
                            prefixIcon: Icon(Icons.access_time_outlined),
                            hintText: 'e.g. 10 AM – 5 PM',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Time slot is required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Hall & Budget
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _selectedHallId,
                          decoration: const InputDecoration(
                            labelText: 'Preferred Hall',
                            prefixIcon: Icon(Icons.meeting_room_outlined),
                          ),
                          items: [
                            const DropdownMenuItem<int>(
                              value: null,
                              child: Text('Any Hall / Not Decided'),
                            ),
                            ...halls.map((h) => DropdownMenuItem<int>(
                              value: h.id,
                              child: Text('${h.name} (${h.capacity} cap)'),
                            )),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedHallId = val;
                              if (val != null) {
                                final hall = halls.firstWhere((h) => h.id == val);
                                _selectedHallName = hall.name;
                              } else {
                                _selectedHallName = null;
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _budgetController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Expected Budget (₹)',
                            prefixIcon: Icon(Icons.currency_rupee),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Status
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(
                      labelText: 'Enquiry Status *',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                    items: _statusOptions
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _status = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes / Special Requirements',
                      hintText: 'e.g. Needs stage decoration, DJ music system, catering preferences...',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save_outlined),
                        label: Text(widget.enquiry == null ? 'Create Enquiry' : 'Save Changes'),
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

