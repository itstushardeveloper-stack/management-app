import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatters.dart';
import '../../data/models/customer.dart';
import '../../providers/app_state.dart';
import 'add_edit_customer_dialog.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _callCustomer(String phone) async {
    final uri = Uri.parse('tel:${phone.replaceAll(RegExp(r'[^0-9+]'), '')}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  void _emailCustomer(String email) async {
    final uri = Uri.parse('mailto:$email');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final customers = state.customers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers Directory'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Customer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          showDialog(context: context, builder: (ctx) => const AddEditCustomerDialog());
        },
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by customer name, phone, email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          state.loadCustomers();
                        },
                      )
                    : null,
                isDense: true,
              ),
              onChanged: (val) {
                state.loadCustomers(searchQuery: val.trim());
              },
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: customers.isEmpty
                ? const Center(child: Text('No customers found.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: customers.length,
                    itemBuilder: (ctx, i) {
                      final c = customers[i];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(c.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.phone, color: AppColors.primary, size: 20),
                                        onPressed: () => _callCustomer(c.phone),
                                      ),
                                      if (c.email != null && c.email!.isNotEmpty)
                                        IconButton(
                                          icon: const Icon(Icons.email, color: AppColors.primary, size: 20),
                                          onPressed: () => _emailCustomer(c.email!),
                                        ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 20),
                                        onPressed: () {
                                          showDialog(context: context, builder: (ctx) => AddEditCustomerDialog(customer: c));
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),

                              Row(
                                children: [
                                  const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 6),
                                  Text(c.phone, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                  if (c.email != null && c.email!.isNotEmpty) ...[
                                    const SizedBox(width: 16),
                                    const Icon(Icons.email_outlined, size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(c.email!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                  ],
                                ],
                              ),

                              if (c.address != null && c.address!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Expanded(child: Text(c.address!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                                  ],
                                ),
                              ],

                              if (c.notes != null && c.notes!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text('Notes: ${c.notes!}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                              ],
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

