import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/date_formatters.dart';
import '../../data/models/expense.dart';
import '../../providers/app_state.dart';

class AddExpenseDialog extends StatefulWidget {
  const AddExpenseDialog({super.key});

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String _category = 'Maintenance';
  DateTime _expenseDate = DateTime.now();
  int? _selectedEventId;

  final List<String> _categories = [
    'Maintenance',
    'Utilities (Electricity/Water)',
    'Staff / Salaries',
    'Catering & Supplies',
    'Decoration & Flowers',
    'Audio / Visual Setup',
    'Taxes & Licensing',
    'Marketing',
    'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final expense = Expense(
      title: _titleController.text.trim(),
      category: _category,
      amount: amount,
      expenseDate: _expenseDate,
      eventId: _selectedEventId,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    final state = Provider.of<AppState>(context, listen: false);
    await state.recordExpense(expense);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = Provider.of<AppState>(context).events;

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
                      const Text('Add Venue Expense', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const Divider(height: 20),

                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Expense Description *', prefixIcon: Icon(Icons.description)),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _category,
                          decoration: const InputDecoration(labelText: 'Category'),
                          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (v) => setState(() => _category = v!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Amount (₹) *', prefixIcon: Icon(Icons.currency_rupee)),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _expenseDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2040),
                            );
                            if (picked != null) setState(() => _expenseDate = picked);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Date', prefixIcon: Icon(Icons.calendar_today)),
                            child: Text(DateFormatters.formatDate(_expenseDate)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          value: _selectedEventId,
                          decoration: const InputDecoration(labelText: 'Link Event (Optional)'),
                          items: [
                            const DropdownMenuItem<int?>(value: null, child: Text('General Overhead')),
                            ...events.map((e) => DropdownMenuItem<int?>(
                                  value: e.id,
                                  child: Text('${e.eventNumber} - ${e.eventType}', overflow: TextOverflow.ellipsis),
                                )),
                          ],
                          onChanged: (v) => setState(() => _selectedEventId = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(labelText: 'Vendor / Receipt Notes'),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                      const SizedBox(width: 10),
                      ElevatedButton(onPressed: _save, child: const Text('Save Expense')),
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

