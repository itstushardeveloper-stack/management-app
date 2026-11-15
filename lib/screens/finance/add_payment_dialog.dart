import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatters.dart';
import '../../core/utils/date_formatters.dart';
import '../../data/models/event_booking.dart';
import '../../data/models/payment.dart';
import '../../providers/app_state.dart';

class AddPaymentDialog extends StatefulWidget {
  final EventBooking? event;

  const AddPaymentDialog({super.key, this.event});

  @override
  State<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<AddPaymentDialog> {
  final _formKey = GlobalKey<FormState>();

  EventBooking? _selectedEvent;
  late TextEditingController _amountController;
  late TextEditingController _refController;
  late TextEditingController _notesController;

  String _paymentType = 'Part Payment';
  String _paymentMethod = 'UPI/Online';
  DateTime _paymentDate = DateTime.now();

  final List<String> _paymentTypes = ['Advance', 'Part Payment', 'Final Balance', 'Security Deposit'];
  final List<String> _paymentMethods = ['UPI/Online', 'Cash', 'Bank Transfer', 'Card', 'Cheque'];

  @override
  void initState() {
    super.initState();
    _selectedEvent = widget.event;
    final defaultAmount = widget.event != null && widget.event!.balanceDue > 0
        ? widget.event!.balanceDue.toStringAsFixed(0)
        : '10000';

    _amountController = TextEditingController(text: defaultAmount);
    _refController = TextEditingController();
    _notesController = TextEditingController();

    if (widget.event != null && widget.event!.advancePaid == 0) {
      _paymentType = 'Advance';
    } else if (widget.event != null && widget.event!.balanceDue > 0) {
      _paymentType = 'Final Balance';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _refController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEvent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an event for this payment')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final payment = Payment(
      eventId: _selectedEvent!.id!,
      customerId: _selectedEvent!.customerId,
      amount: amount,
      paymentType: _paymentType,
      paymentMethod: _paymentMethod,
      paymentDate: _paymentDate,
      transactionRef: _refController.text.trim().isNotEmpty ? _refController.text.trim() : null,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    final state = Provider.of<AppState>(context, listen: false);
    await state.recordPayment(payment);

    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment of ${CurrencyFormatters.format(amount)} recorded successfully!'),
          backgroundColor: AppColors.confirmed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final events = state.events.where((e) => e.status != 'Cancelled').toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
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
                      const Text('Record Payment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const Divider(height: 20),

                  // Event Selector if not fixed
                  if (widget.event == null) ...[
                    DropdownButtonFormField<int>(
                      value: _selectedEvent?.id,
                      decoration: const InputDecoration(labelText: 'Select Event *', prefixIcon: Icon(Icons.event)),
                      items: events
                          .map((e) => DropdownMenuItem<int>(
                                value: e.id,
                                child: Text('${e.eventNumber} - ${e.customerName} (${CurrencyFormatters.format(e.balanceDue)} due)'),
                              ))
                          .toList(),
                      onChanged: (id) {
                        setState(() {
                          _selectedEvent = events.firstWhere((e) => e.id == id);
                          if (_selectedEvent!.balanceDue > 0) {
                            _amountController.text = _selectedEvent!.balanceDue.toStringAsFixed(0);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${_selectedEvent!.eventNumber} • ${_selectedEvent!.customerName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('${_selectedEvent!.eventType} (${_selectedEvent!.hallName})', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Balance Due', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              Text(CurrencyFormatters.format(_selectedEvent!.balanceDue), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.newEnquiry)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Amount
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Payment Amount (₹) *',
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  // Type and Method
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _paymentType,
                          decoration: const InputDecoration(labelText: 'Payment Type'),
                          items: _paymentTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (v) => setState(() => _paymentType = v!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _paymentMethod,
                          decoration: const InputDecoration(labelText: 'Method'),
                          items: _paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                          onChanged: (v) => setState(() => _paymentMethod = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Date & Ref
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _paymentDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2040),
                            );
                            if (picked != null) setState(() => _paymentDate = picked);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Payment Date', prefixIcon: Icon(Icons.calendar_today)),
                            child: Text(DateFormatters.formatDate(_paymentDate)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _refController,
                          decoration: const InputDecoration(
                            labelText: 'Txn / UPI / Cheque Ref',
                            prefixIcon: Icon(Icons.receipt_long),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      hintText: 'e.g. Received via GPay, confirmed receipt sent',
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.confirmed),
                        icon: const Icon(Icons.check),
                        label: const Text('Record Payment'),
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

