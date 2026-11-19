import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_state.dart';
import 'dashboard/dashboard_screen.dart';
import 'enquiries/enquiries_screen.dart';
import 'calendar/google_calendar_screen.dart';
import 'events/events_screen.dart';
import 'customers/customers_screen.dart';
import 'finance/finance_reports_screen.dart';
import 'settings/backup_restore_screen.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  final List<Widget> _screens = const [
    DashboardScreen(),
    EnquiriesScreen(),
    GoogleCalendarScreen(),
    EventsScreen(),
    CustomersScreen(),
    FinanceReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final currentIndex = state.currentTabIndex;
    final isWide = MediaQuery.of(context).size.width >= 800;

    if (state.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing Event & Venue Manager...', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    if (isWide) {
      // Wide layout (Desktop / Tablet / Web)
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: (index) {
                if (index < _screens.length) {
                  state.setTabIndex(index);
                }
              },
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  radius: 20,
                  child: const Icon(Icons.apartment, color: Colors.white),
                ),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: IconButton(
                      icon: const Icon(Icons.settings_backup_restore),
                      tooltip: 'Backup & Restore',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (ctx) => const BackupRestoreScreen()),
                        );
                      },
                    ),
                  ),
                ),
              ),
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
                NavigationRailDestination(icon: Icon(Icons.contact_phone_outlined), selectedIcon: Icon(Icons.contact_phone), label: Text('Enquiries')),
                NavigationRailDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: Text('Calendar')),
                NavigationRailDestination(icon: Icon(Icons.event_available_outlined), selectedIcon: Icon(Icons.event_available), label: Text('Events')),
                NavigationRailDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: Text('Customers')),
                NavigationRailDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: Text('Finance')),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: _screens[currentIndex]),
          ],
        ),
      );
    }

    // Mobile layout (Bottom Navigation Bar)
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.apartment, color: Colors.white, size: 36),
                  const SizedBox(height: 8),
                  const Text('Event & Venue Manager', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('${state.events.length} Bookings • ${state.enquiries.length} Enquiries', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Dashboard'),
              selected: currentIndex == 0,
              onTap: () {
                state.setTabIndex(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.contact_phone_outlined),
              title: const Text('Enquiries & Leads'),
              selected: currentIndex == 1,
              trailing: state.followUpReminders.isNotEmpty
                  ? CircleAvatar(
                      radius: 10,
                      backgroundColor: AppColors.followUp,
                      child: Text('${state.followUpReminders.length}', style: const TextStyle(fontSize: 10, color: Colors.white)),
                    )
                  : null,
              onTap: () {
                state.setTabIndex(1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: const Text('Google Calendar Schedule'),
              selected: currentIndex == 2,
              onTap: () {
                state.setTabIndex(2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_available_outlined),
              title: const Text('Confirmed Events'),
              selected: currentIndex == 3,
              onTap: () {
                state.setTabIndex(3);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Customers'),
              selected: currentIndex == 4,
              onTap: () {
                state.setTabIndex(4);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart_outlined),
              title: const Text('Finance & Reports'),
              selected: currentIndex == 5,
              onTap: () {
                state.setTabIndex(5);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_backup_restore),
              title: const Text('Backup & Offline Data'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => const BackupRestoreScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: _screens[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => state.setTabIndex(index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: state.followUpReminders.isNotEmpty,
              label: Text('${state.followUpReminders.length}'),
              child: const Icon(Icons.contact_phone_outlined),
            ),
            selectedIcon: const Icon(Icons.contact_phone),
            label: 'Enquiries',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          const NavigationDestination(
            icon: Icon(Icons.event_available_outlined),
            selectedIcon: Icon(Icons.event_available),
            label: 'Events',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Customers',
          ),
          const NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Finance',
          ),
        ],
      ),
    );
  }
}

