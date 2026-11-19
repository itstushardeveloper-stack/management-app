import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatters.dart';
import '../../core/utils/date_formatters.dart';
import '../../data/models/event_booking.dart';
import '../../data/models/enquiry.dart';
import '../../providers/app_state.dart';
import '../events/add_edit_event_dialog.dart';
import '../enquiries/enquiry_detail_sheet.dart';
import 'event_detail_popup.dart';

class GoogleCalendarScreen extends StatefulWidget {
  const GoogleCalendarScreen({super.key});

  @override
  State<GoogleCalendarScreen> createState() => _GoogleCalendarScreenState();
}

class _GoogleCalendarScreenState extends State<GoogleCalendarScreen> {
  final TextEditingController _dateSearchController = TextEditingController();

  @override
  void dispose() {
    _dateSearchController.dispose();
    super.dispose();
  }

  void _showEventDetail(EventBooking event) {
    showDialog(
      context: context,
      builder: (ctx) => EventDetailPopup(event: event),
    );
  }

  void _showEnquiryDetail(Enquiry enquiry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.88,
        child: EnquiryDetailSheet(enquiry: enquiry),
      ),
    );
  }

  void _createNewEvent([DateTime? date]) async {
    final state = Provider.of<AppState>(context, listen: false);
    final targetDate = date ?? state.selectedDate;
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AddEditEventDialog(initialDate: targetDate),
    );
    if (res == true) {
      state.refreshAll();
    }
  }

  Future<void> _pickDateToJump() async {
    final state = Provider.of<AppState>(context, listen: false);
    final picked = await showDatePicker(
      context: context,
      initialDate: state.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      state.setSelectedDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final selectedDate = state.selectedDate;
    final view = state.calendarView;

    final filteredEvents = state.events;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              DateFormatters.formatMonthYear(selectedDate),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_drop_down),
              tooltip: 'Pick date',
              onPressed: _pickDateToJump,
            ),
          ],
        ),
        actions: [
          // Today button
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
            ),
            onPressed: () => state.goToToday(),
            child: const Text('Today', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 4),

          // Prev / Next Buttons
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous',
            onPressed: () => state.prevCalendarPeriod(),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next',
            onPressed: () => state.nextCalendarPeriod(),
          ),

          // View Selector Menu (Month, Week, Day, Agenda)
          PopupMenuButton<CalendarViewType>(
            tooltip: 'Switch view',
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  view.name[0].toUpperCase() + view.name.substring(1),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
            onSelected: (val) => state.setCalendarView(val),
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: CalendarViewType.month,
                child: Row(children: [Icon(Icons.calendar_view_month), SizedBox(width: 8), Text('Month View')]),
              ),
              const PopupMenuItem(
                value: CalendarViewType.week,
                child: Row(children: [Icon(Icons.calendar_view_week), SizedBox(width: 8), Text('Week View')]),
              ),
              const PopupMenuItem(
                value: CalendarViewType.day,
                child: Row(children: [Icon(Icons.calendar_view_day), SizedBox(width: 8), Text('Day View')]),
              ),
              const PopupMenuItem(
                value: CalendarViewType.agenda,
                child: Row(children: [Icon(Icons.view_agenda_outlined), SizedBox(width: 8), Text('Agenda View')]),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        tooltip: 'Add event on ${DateFormatters.formatDateShort(selectedDate)}',
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _createNewEvent(selectedDate),
      ),
      body: Column(
        children: [
          // Main Calendar View Body
          Expanded(
            child: _buildCalendarView(view, selectedDate, filteredEvents, state.enquiries),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView(
    CalendarViewType view,
    DateTime selectedDate,
    List<EventBooking> events,
    List<Enquiry> enquiries,
  ) {
    switch (view) {
      case CalendarViewType.month:
        return _buildMonthView(selectedDate, events, enquiries);
      case CalendarViewType.week:
        return _buildWeekView(selectedDate, events);
      case CalendarViewType.day:
        return _buildDayView(selectedDate, events, enquiries);
      case CalendarViewType.agenda:
        return _buildAgendaView(events, enquiries);
    }
  }

  // --- 1. MONTH VIEW ---
  Widget _buildMonthView(
    DateTime selectedDate,
    List<EventBooking> events,
    List<Enquiry> enquiries,
  ) {
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final daysInMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    final startingWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0

    // Selected date events
    final selectedDateStr = DateFormatters.formatIsoDate(selectedDate);
    final dayEvents = events.where((e) {
      return DateFormatters.formatIsoDate(e.eventDate) == selectedDateStr && e.status != 'Cancelled';
    }).toList();

    // Selected date follow-ups
    final dayFollowUps = enquiries.where((enq) {
      if (enq.followUpDate == null) return false;
      return DateFormatters.formatIsoDate(enq.followUpDate!) == selectedDateStr &&
          enq.status != 'Confirmed' &&
          enq.status != 'Lost' &&
          enq.status != 'Cancelled';
    }).toList();

    const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Column(
      children: [
        // Days of week header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: weekdays
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        const Divider(height: 1),

        // 7x5 or 7x6 Month Grid
        Expanded(
          flex: 5,
          child: Container(
            color: Colors.white,
            child: GridView.builder(
              padding: const EdgeInsets.all(4),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.85,
              ),
              itemCount: 42,
              itemBuilder: (ctx, index) {
                final dayNumber = index - startingWeekday + 1;
                final isCurrentMonth = dayNumber >= 1 && dayNumber <= daysInMonth;

                DateTime cellDate;
                if (isCurrentMonth) {
                  cellDate = DateTime(selectedDate.year, selectedDate.month, dayNumber);
                } else if (dayNumber < 1) {
                  final prevMonthDays = DateTime(selectedDate.year, selectedDate.month, 0).day;
                  cellDate = DateTime(selectedDate.year, selectedDate.month - 1, prevMonthDays + dayNumber);
                } else {
                  cellDate = DateTime(selectedDate.year, selectedDate.month + 1, dayNumber - daysInMonth);
                }

                final isToday = DateFormatters.isSameDay(cellDate, DateTime.now());
                final isSelected = DateFormatters.isSameDay(cellDate, selectedDate);

                // Find events on this day
                final cellDateStr = DateFormatters.formatIsoDate(cellDate);
                final cellEvents = events.where((e) {
                  return DateFormatters.formatIsoDate(e.eventDate) == cellDateStr && e.status != 'Cancelled';
                }).toList();

                final hasFollowUp = enquiries.any((enq) {
                  return enq.followUpDate != null &&
                      DateFormatters.formatIsoDate(enq.followUpDate!) == cellDateStr &&
                      enq.status != 'Confirmed' &&
                      enq.status != 'Lost' &&
                      enq.status != 'Cancelled';
                });

                return InkWell(
                  onTap: () {
                    Provider.of<AppState>(context, listen: false).setSelectedDate(cellDate);
                  },
                  onLongPress: () => _createNewEvent(cellDate),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryLight.withOpacity(0.5)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: AppColors.primary, width: 1.5)
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 2),
                        // Date circle
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppColors.primary
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${cellDate.day}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isToday
                                  ? Colors.white
                                  : (isCurrentMonth ? AppColors.textPrimary : AppColors.textMuted.withOpacity(0.5)),
                            ),
                          ),
                        ),

                        // Event indicators / badges
                        const Spacer(),
                        if (cellEvents.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 3),
                              decoration: BoxDecoration(
                                color: AppColors.confirmed,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                cellEvents.length == 1
                                    ? cellEvents.first.eventType
                                    : '${cellEvents.length} Events',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),

                        if (hasFollowUp)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.followUp,
                              shape: BoxShape.circle,
                            ),
                          ),
                        const SizedBox(height: 2),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        const Divider(height: 1),

        // Selected Date Bottom Events Drawer
        Expanded(
          flex: 4,
          child: Container(
            color: AppColors.background,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Selected date: ${DateFormatters.formatDayDate(selectedDate)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Event', style: TextStyle(fontSize: 12)),
                        onPressed: () => _createNewEvent(selectedDate),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: (dayEvents.isEmpty && dayFollowUps.isEmpty)
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.event_available, color: AppColors.textMuted, size: 36),
                              const SizedBox(height: 8),
                              const Text('No bookings or follow-ups for this date', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              const SizedBox(height: 4),
                              TextButton(
                                onPressed: () => _createNewEvent(selectedDate),
                                child: const Text('+ Tap to schedule an event'),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          children: [
                            // Follow-ups section
                            ...dayFollowUps.map((enq) => Card(
                                  color: AppColors.followUpLight,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor: AppColors.followUp,
                                      radius: 18,
                                      child: Icon(Icons.alarm, color: Colors.white, size: 18),
                                    ),
                                    title: Text('Follow-up: ${enq.customerName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    subtitle: Text('${enq.eventType} • ${enq.phone} • Budget: ${CurrencyFormatters.format(enq.expectedBudget)}'),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () => _showEnquiryDetail(enq),
                                  ),
                                )),

                            // Confirmed events section (matches the exact example in the user prompt!)
                            ...dayEvents.map((evt) => Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: InkWell(
                                    onTap: () => _showEventDetail(evt),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                evt.customerName,
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.confirmedLight,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  evt.status,
                                                  style: const TextStyle(
                                                    color: AppColors.confirmed,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${evt.eventType} · ${evt.guests} guests',
                                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                                              const SizedBox(width: 4),
                                              Text('${evt.startTime} – ${evt.endTime}', style: const TextStyle(fontSize: 12)),
                                              const SizedBox(width: 12),
                                              const Icon(Icons.meeting_room_outlined, size: 14, color: AppColors.textSecondary),
                                              const SizedBox(width: 4),
                                              Text(evt.hallName, style: const TextStyle(fontSize: 12)),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                CurrencyFormatters.format(evt.totalCost),
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
                                              ),
                                              const Text('Tap to view details >', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- 2. WEEK VIEW ---
  Widget _buildWeekView(DateTime selectedDate, List<EventBooking> events) {
    // Start of week (Sunday)
    final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday % 7));
    final weekDays = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    return Row(
      children: weekDays.map((day) {
        final dayStr = DateFormatters.formatIsoDate(day);
        final dayEvents = events.where((e) {
          return DateFormatters.formatIsoDate(e.eventDate) == dayStr && e.status != 'Cancelled';
        }).toList();

        final isToday = DateFormatters.isSameDay(day, DateTime.now());
        final isSelected = DateFormatters.isSameDay(day, selectedDate);

        return Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: AppColors.outlineLight)),
              color: isSelected ? AppColors.primaryLight.withOpacity(0.2) : Colors.white,
            ),
            child: Column(
              children: [
                // Day header
                InkWell(
                  onTap: () {
                    Provider.of<AppState>(context, listen: false).setSelectedDate(day);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: isToday ? AppColors.primaryLight : Colors.transparent,
                    child: Column(
                      children: [
                        Text(
                          DateFormatters.formatDayDate(day).split(',')[0],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isToday ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                            color: isToday ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),

                // Events in this day
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(4),
                    itemCount: dayEvents.length,
                    itemBuilder: (ctx, i) {
                      final ev = dayEvents[i];
                      return InkWell(
                        onTap: () => _showEventDetail(ev),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ev.startTime, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                              Text(ev.eventType, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), maxLines: 1),
                              Text(ev.hallName.split('(')[0].trim(), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), maxLines: 1),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- 3. DAY VIEW ---
  Widget _buildDayView(DateTime selectedDate, List<EventBooking> events, List<Enquiry> enquiries) {
    final dayStr = DateFormatters.formatIsoDate(selectedDate);
    final dayEvents = events.where((e) {
      return DateFormatters.formatIsoDate(e.eventDate) == dayStr && e.status != 'Cancelled';
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          DateFormatters.formatDayDate(selectedDate),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        if (dayEvents.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            child: Column(
              children: [
                const Icon(Icons.event_busy, size: 48, color: AppColors.textMuted),
                const SizedBox(height: 12),
                const Text('No bookings scheduled on this day.', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Booking'),
                  onPressed: () => _createNewEvent(selectedDate),
                ),
              ],
            ),
          )
        else
          ...dayEvents.map((evt) => Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(evt.eventType, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.confirmedLight, borderRadius: BorderRadius.circular(6)),
                            child: Text(evt.status, style: const TextStyle(color: AppColors.confirmed, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Customer: ${evt.customerName} (${evt.phone})', style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('Hall: ${evt.hallName} • Guests: ${evt.guests}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text('Time: ${evt.startTime} – ${evt.endTime}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total: ${CurrencyFormatters.format(evt.totalCost)} (Bal: ${CurrencyFormatters.format(evt.balanceDue)})', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ElevatedButton(
                            onPressed: () => _showEventDetail(evt),
                            child: const Text('Manage Event'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
      ],
    );
  }

  // --- 4. AGENDA VIEW ---
  Widget _buildAgendaView(List<EventBooking> events, List<Enquiry> enquiries) {
    final activeEvents = events.where((e) => e.status != 'Cancelled').toList();
    if (activeEvents.isEmpty) {
      return const Center(child: Text('No upcoming events scheduled.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeEvents.length,
      itemBuilder: (ctx, i) {
        final ev = activeEvents[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${ev.eventDate.day}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                Text(
                  DateFormatters.formatMonthYear(ev.eventDate).split(' ')[0].substring(0, 3).toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            title: Text('${ev.customerName} - ${ev.eventType}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${ev.hallName.split('(')[0]} • ${ev.startTime} - ${ev.endTime}'),
            trailing: Text(CurrencyFormatters.format(ev.totalCost), style: const TextStyle(fontWeight: FontWeight.bold)),
            onTap: () => _showEventDetail(ev),
          ),
        );
      },
    );
  }
}

