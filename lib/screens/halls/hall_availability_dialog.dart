import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatters.dart';
import '../../data/models/hall.dart';
import '../../data/models/hall_hold.dart';
import '../../providers/app_state.dart';

class HallAvailabilityDialog extends StatefulWidget {
  const HallAvailabilityDialog({super.key});

  @override
  State<HallAvailabilityDialog> createState() => _HallAvailabilityDialogState();
}

class _HallAvailabilityDialogState extends State<HallAvailabilityDialog> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _startTime = '10:00 AM';
  String _endTime = '05:00 PM';
  int? _selectedHallId;

  bool _hasChecked = false;
  bool _isChecking = false;
  bool _isAvailable = false;
  String? _conflictReason;

  // Temporary Hold fields
  bool _showHoldForm = false;
  final _holdReasonController = TextEditingController();
  DateTime _holdExpiry = DateTime.now().add(const Duration(days: 2));

  @override
  void dispose() {
    _holdReasonController.dispose();
    super.dispose();
  }

  Future<void> _checkAvailability() async {
    if (_selectedHallId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a hall first')),
      );
      return;
    }

    setState(() {
      _isChecking = true;
      _hasChecked = true;
    });

    final state = Provider.of<AppState>(context, listen: false);
    final res = await state.checkHallAvailability(
      hallId: _selectedHallId!,
      date: _selectedDate,
      startTime: _startTime,
      endTime: _endTime,
    );

    if (mounted) {
      setState(() {
        _isChecking = false;
        _isAvailable = res.isAvailable;
        _conflictReason = res.conflictReason;
      });
    }
  }

  Future<void> _createTemporaryHold() async {
    if (_holdReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a hold reason/client name')),
      );
      return;
    }

    final hold = HallHold(
      hallId: _selectedHallId!,
      holdDate: _selectedDate,
      startTime: _startTime,
      endTime: _endTime,
      reason: _holdReasonController.text.trim(),
      expiresAt: _holdExpiry,
    );

    final state = Provider.of<AppState>(context, listen: false);
    await state.hallRepo.createHold(hold);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Temporary hold registered until ${DateFormatters.formatDateShort(_holdExpiry)}!'),
          backgroundColor: AppColors.confirmed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final halls = Provider.of<AppState>(context).halls;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Check Hall Availability', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const Divider(height: 20),

                // Venue Picker
                DropdownButtonFormField<int>(
                  value: _selectedHallId,
                  decoration: const InputDecoration(labelText: 'Select Hall / Venue', prefixIcon: Icon(Icons.meeting_room)),
                  items: halls
                      .map((h) => DropdownMenuItem<int>(
                            value: h.id,
                            child: Text('${h.name} (${h.capacity} guests)'),
                          ))
                      .toList(),
                  onChanged: (id) {
                    setState(() {
                      _selectedHallId = id;
                      _hasChecked = false;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Date Picker
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2040),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                        _hasChecked = false;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Event Date', prefixIcon: Icon(Icons.calendar_today)),
                    child: Text(DateFormatters.formatDayDate(_selectedDate)),
                  ),
                ),
                const SizedBox(height: 12),

                // Time Pickers
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _startTime,
                        decoration: const InputDecoration(labelText: 'Start Time', prefixIcon: Icon(Icons.access_time)),
                        onChanged: (v) {
                          _startTime = v;
                          _hasChecked = false;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        initialValue: _endTime,
                        decoration: const InputDecoration(labelText: 'End Time', prefixIcon: Icon(Icons.access_time)),
                        onChanged: (v) {
                          _endTime = v;
                          _hasChecked = false;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Verify Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: _isChecking
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.search),
                    label: const Text('Verify Availability'),
                    onPressed: _isChecking ? null : _checkAvailability,
                  ),
                ),
                const SizedBox(height: 16),

                // Result Box
                if (_hasChecked) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _isAvailable ? AppColors.confirmedLight : AppColors.lostLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _isAvailable ? AppColors.confirmed : AppColors.lost),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(_isAvailable ? Icons.check_circle : Icons.cancel, color: _isAvailable ? AppColors.confirmed : AppColors.lost),
                            const SizedBox(width: 8),
                            Text(
                              _isAvailable ? 'AVAILABLE FOR BOOKING!' : 'NOT AVAILABLE',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: _isAvailable ? AppColors.confirmed : AppColors.lost,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isAvailable
                            ? 'No conflicting confirmed bookings or holds found for this date and time.'
                            : (_conflictReason ?? 'Time slot overlaps with another reservation.'),
                          style: TextStyle(color: _isAvailable ? AppColors.confirmed : AppColors.lost, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Option to put a temporary hold if available
                  if (_isAvailable && !_showHoldForm)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.bookmark_add_outlined),
                      label: const Text('Place a Temporary Hold with Expiry'),
                      onPressed: () => setState(() => _showHoldForm = true),
                    ),

                  if (_showHoldForm) ...[
                    const Divider(height: 20),
                    const Text('Temporary Reservation Hold', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _holdReasonController,
                      decoration: const InputDecoration(
                        labelText: 'Hold For / Reason *',
                        hintText: 'e.g. Tentative booking for Verma wedding...',
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _holdExpiry,
                          firstDate: DateTime.now(),
                          lastDate: _selectedDate,
                        );
                        if (picked != null) setState(() => _holdExpiry = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Hold Expiration Date'),
                        child: Text(DateFormatters.formatDate(_holdExpiry)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.followUp),
                      icon: const Icon(Icons.lock_clock),
                      label: const Text('Confirm Temporary Hold'),
                      onPressed: _createTemporaryHold,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

