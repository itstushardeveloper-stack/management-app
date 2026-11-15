import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/hall.dart';
import '../../providers/app_state.dart';

class AddEditHallDialog extends StatefulWidget {
  final Hall? hall;

  const AddEditHallDialog({super.key, this.hall});

  @override
  State<AddEditHallDialog> createState() => _AddEditHallDialogState();
}

class _AddEditHallDialogState extends State<AddEditHallDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _capacityController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  late TextEditingController _amenitiesController;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final h = widget.hall;
    _nameController = TextEditingController(text: h?.name ?? '');
    _capacityController = TextEditingController(text: h != null ? '${h.capacity}' : '300');
    _priceController = TextEditingController(text: h != null ? h.basePrice.toStringAsFixed(0) : '40000');
    _descController = TextEditingController(text: h?.description ?? '');
    _amenitiesController = TextEditingController(text: h?.amenities ?? '');
    _isActive = h?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _amenitiesController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final capacity = int.tryParse(_capacityController.text.trim()) ?? 100;
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;

    final hall = Hall(
      id: widget.hall?.id,
      name: _nameController.text.trim(),
      capacity: capacity,
      basePrice: price,
      description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
      amenities: _amenitiesController.text.trim().isNotEmpty ? _amenitiesController.text.trim() : null,
      isActive: _isActive,
    );

    final state = Provider.of<AppState>(context, listen: false);
    await state.saveHall(hall);

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
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                      Text(widget.hall == null ? 'Add New Hall / Venue' : 'Edit Hall Details',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const Divider(height: 20),

                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Hall Name *', prefixIcon: Icon(Icons.meeting_room)),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _capacityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Max Guest Capacity *', prefixIcon: Icon(Icons.group)),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Base Rate (₹) *', prefixIcon: Icon(Icons.currency_rupee)),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _amenitiesController,
                    decoration: const InputDecoration(
                      labelText: 'Amenities (Comma separated)',
                      hintText: 'e.g. AC, Sound System, Bridal Room, Generator, Projector',
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _descController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Description / Features'),
                  ),
                  const SizedBox(height: 12),

                  SwitchListTile(
                    title: const Text('Hall is Active for Booking'),
                    value: _isActive,
                    onChanged: (val) => setState(() => _isActive = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                      const SizedBox(width: 10),
                      ElevatedButton(onPressed: _save, child: const Text('Save Hall')),
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

