import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatters.dart';
import '../../data/models/hall.dart';
import '../../providers/app_state.dart';
import 'add_edit_hall_dialog.dart';
import 'hall_availability_dialog.dart';

class HallsScreen extends StatelessWidget {
  const HallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final halls = state.halls;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Halls & Venues'),
        actions: [
          IconButton(
            tooltip: 'Check Availability',
            icon: const Icon(Icons.event_available),
            onPressed: () {
              showDialog(context: context, builder: (ctx) => const HallAvailabilityDialog());
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Hall', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          showDialog(context: context, builder: (ctx) => const AddEditHallDialog());
        },
      ),
      body: Column(
        children: [
          // Availability check banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Hall Availability & Slots', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('${halls.length} Venues configured in system', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Slot Checker', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    showDialog(context: context, builder: (ctx) => const HallAvailabilityDialog());
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: halls.isEmpty
                ? const Center(child: Text('No halls added yet. Tap "+ Add Hall" to create one.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: halls.length,
                    itemBuilder: (ctx, i) {
                      final hall = halls[i];
                      final amenitiesList = hall.amenities?.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() ?? [];

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      hall.name,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: hall.isActive ? AppColors.confirmedLight : AppColors.cancelledLight,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      hall.isActive ? 'Active' : 'Inactive',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: hall.isActive ? AppColors.confirmed : AppColors.cancelled,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              Row(
                                children: [
                                  const Icon(Icons.group, size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 6),
                                  Text('Capacity: ${hall.capacity} Guests', style: const TextStyle(fontWeight: FontWeight.w500)),
                                  const SizedBox(width: 16),
                                  const Icon(Icons.currency_rupee, size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text('Base Price: ${CurrencyFormatters.format(hall.basePrice)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                                ],
                              ),
                              const SizedBox(height: 8),

                              if (hall.description != null && hall.description!.isNotEmpty) ...[
                                Text(hall.description!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                const SizedBox(height: 8),
                              ],

                              if (amenitiesList.isNotEmpty) ...[
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: amenitiesList.map((a) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceVariant,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: AppColors.outlineLight),
                                      ),
                                      child: Text(a, style: const TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 12),
                              ],

                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(Icons.edit_outlined, size: 16),
                                    label: const Text('Edit'),
                                    onPressed: () {
                                      showDialog(context: context, builder: (ctx) => AddEditHallDialog(hall: hall));
                                    },
                                  ),
                                ],
                              ),
                            ],
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

