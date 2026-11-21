import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatters.dart';
import '../../core/utils/date_formatters.dart';
import '../../data/models/expense.dart';
import '../../providers/app_state.dart';
import 'add_payment_dialog.dart';
import 'add_expense_dialog.dart';

class FinanceReportsScreen extends StatefulWidget {
  const FinanceReportsScreen({super.key});

  @override
  State<FinanceReportsScreen> createState() => _FinanceReportsScreenState();
}

class _FinanceReportsScreenState extends State<FinanceReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _detailedPayments = [];
  List<Expense> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFinanceData();
  }

  Future<void> _loadFinanceData() async {
    final state = Provider.of<AppState>(context, listen: false);
    final payments = await state.paymentRepo.getAllPaymentsDetailed();
    final expenses = await state.expenseRepo.getAllExpenses();

    if (mounted) {
      setState(() {
        _detailedPayments = payments;
        _expenses = expenses;
        _isLoading = false;
      });
    }
  }

  void _shareReportSummary() {
    final state = Provider.of<AppState>(context, listen: false);
    final totalEnquiries = state.enquiries.length;
    final confirmedEvents = state.events.where((e) => e.status == 'Confirmed').length;
    final conversionRate = totalEnquiries > 0
        ? ((confirmedEvents / totalEnquiries) * 100).toStringAsFixed(1)
        : '0.0';

    final summary = '''
*EVENT & VENUE MANAGEMENT - FINANCIAL & PERFORMANCE REPORT*
Generated: ${DateFormatters.formatDate(DateTime.now())}

--- FINANCIAL OVERVIEW ---
Total Collected Revenue: ${CurrencyFormatters.format(state.totalIncome)}
Pending Balance to Collect: ${CurrencyFormatters.format(state.totalBalancePending)}
Total Operational Expenses: ${CurrencyFormatters.format(state.totalExpenses)}
Net Profit: ${CurrencyFormatters.format(state.netProfit)}

--- CONVERSION & CRM PERFORMANCE ---
Total Enquiries Received: $totalEnquiries
Confirmed Bookings: $confirmedEvents
Enquiry-to-Booking Conversion Rate: $conversionRate%
''';

    Share.share(summary, subject: 'Event Venue Financial Report');
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final totalEnquiries = state.enquiries.length;
    final convertedEnquiries = state.enquiries.where((e) => e.isConverted).length;
    final conversionRate = totalEnquiries > 0
        ? ((convertedEnquiries / totalEnquiries) * 100).toStringAsFixed(1)
        : '0.0';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance & Reports'),
        actions: [
          IconButton(
            tooltip: 'Share Report',
            icon: const Icon(Icons.share),
            onPressed: _shareReportSummary,
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              state.refreshAll();
              _loadFinanceData();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Income / Payments'),
            Tab(text: 'Expenses'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Financial & Business Overview
          RefreshIndicator(
            onRefresh: () async {
              await state.refreshAll();
              await _loadFinanceData();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Revenue Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        'Total Collected',
                        CurrencyFormatters.format(state.totalIncome),
                        AppColors.confirmed,
                        AppColors.confirmedLight,
                        Icons.payments,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        'Pending Balances',
                        CurrencyFormatters.format(state.totalBalancePending),
                        AppColors.newEnquiry,
                        AppColors.newEnquiryLight,
                        Icons.pending_actions,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        'Total Expenses',
                        CurrencyFormatters.format(state.totalExpenses),
                        AppColors.followUp,
                        AppColors.followUpLight,
                        Icons.shopping_cart,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        'Net Profit',
                        CurrencyFormatters.format(state.netProfit),
                        AppColors.primary,
                        AppColors.primaryLight,
                        Icons.account_balance,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Enquiry-to-Booking Conversion Rate Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.outlineLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Enquiry Conversion Rate',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$conversionRate% Converted',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: totalEnquiries > 0 ? (convertedEnquiries / totalEnquiries) : 0,
                          minHeight: 10,
                          backgroundColor: AppColors.surfaceVariant,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _conversionStat('Total Enquiries', '$totalEnquiries'),
                          _conversionStat('Converted to Events', '$convertedEnquiries'),
                          _conversionStat('Active Leads', '${state.enquiries.where((e) => !e.isConverted && e.status != "Lost" && e.status != "Cancelled").length}'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.confirmed),
                        icon: const Icon(Icons.add),
                        label: const Text('Record Payment'),
                        onPressed: () async {
                          final res = await showDialog(context: context, builder: (ctx) => const AddPaymentDialog());
                          if (res == true) _loadFinanceData();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Expense'),
                        onPressed: () async {
                          final res = await showDialog(context: context, builder: (ctx) => const AddExpenseDialog());
                          if (res == true) _loadFinanceData();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Recent Transactions List
                const Text('Recent Payment Collections', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_detailedPayments.isEmpty)
                  const Text('No payments recorded yet.')
                else
                  ..._detailedPayments.take(4).map((p) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(backgroundColor: AppColors.confirmedLight, child: Icon(Icons.arrow_downward, color: AppColors.confirmed)),
                          title: Text('${p['customer_name']} (${p['event_number']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${p['payment_type']} • ${p['payment_method']} • ${DateFormatters.formatDate(DateTime.parse(p['payment_date']))}'),
                          trailing: Text(CurrencyFormatters.format((p['amount'] as num).toDouble()), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.confirmed)),
                        ),
                      )),
              ],
            ),
          ),

          // Tab 2: All Payments Ledger
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _detailedPayments.isEmpty
                  ? const Center(child: Text('No payments registered'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _detailedPayments.length,
                      itemBuilder: (ctx, i) {
                        final p = _detailedPayments[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const CircleAvatar(backgroundColor: AppColors.confirmedLight, child: Icon(Icons.receipt, color: AppColors.confirmed)),
                            title: Text('${p['customer_name']} - ${p['event_number']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${p['payment_type']} via ${p['payment_method']} • ${DateFormatters.formatDate(DateTime.parse(p['payment_date']))}\nRef: ${p['transaction_ref'] ?? "N/A"}'),
                            isThreeLine: true,
                            trailing: Text(CurrencyFormatters.format((p['amount'] as num).toDouble()), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.confirmed)),
                          ),
                        );
                      },
                    ),

          // Tab 3: All Expenses
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _expenses.isEmpty
                  ? const Center(child: Text('No expenses recorded'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _expenses.length,
                      itemBuilder: (ctx, i) {
                        final ex = _expenses[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const CircleAvatar(backgroundColor: AppColors.lostLight, child: Icon(Icons.arrow_upward, color: AppColors.lost)),
                            title: Text(ex.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${ex.category} • ${DateFormatters.formatDate(ex.expenseDate)}${ex.notes != null ? "\n${ex.notes}" : ""}'),
                            trailing: Text(CurrencyFormatters.format(ex.amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.lost)),
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color, Color bg, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              CircleAvatar(backgroundColor: bg, radius: 14, child: Icon(icon, size: 14, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _conversionStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

