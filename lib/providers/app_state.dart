import 'package:flutter/foundation.dart';
import '../data/models/enquiry.dart';
import '../data/models/event_booking.dart';
import '../data/models/hall.dart';
import '../data/models/customer.dart';
import '../data/models/follow_up.dart';
import '../data/models/payment.dart';
import '../data/models/expense.dart';
import '../data/repositories/enquiry_repository.dart';
import '../data/repositories/event_repository.dart';
import '../data/repositories/hall_repository.dart';
import '../data/repositories/customer_repository.dart';
import '../data/repositories/payment_repository.dart';
import '../data/repositories/expense_repository.dart';
import '../data/database/sample_data.dart';
import '../core/utils/date_formatters.dart';

enum CalendarViewType { month, week, day, agenda }

class AppState extends ChangeNotifier {
  final EnquiryRepository _enquiryRepo = EnquiryRepository();
  final EventRepository _eventRepo = EventRepository();
  final HallRepository _hallRepo = HallRepository();
  final CustomerRepository _customerRepo = CustomerRepository();
  final PaymentRepository _paymentRepo = PaymentRepository();
  final ExpenseRepository _expenseRepo = ExpenseRepository();

  // Navigation Shell State
  int _currentTabIndex = 0;
  int get currentTabIndex => _currentTabIndex;

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  // Data Collections
  List<Enquiry> _enquiries = [];
  List<EventBooking> _events = [];
  List<Hall> _halls = [];
  List<Customer> _customers = [];
  List<Enquiry> _followUpReminders = [];
  List<EventBooking> _todayEvents = [];

  // Financial Stats
  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;
  double _totalBalancePending = 0.0;

  // Calendar Controls
  DateTime _selectedDate = DateTime.now();
  CalendarViewType _calendarView = CalendarViewType.month;
  int? _calendarHallFilter;

  // Loading State
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Enquiry> get enquiries => _enquiries;
  List<EventBooking> get events => _events;
  List<Hall> get halls => _halls;
  List<Customer> get customers => _customers;
  List<Enquiry> get followUpReminders => _followUpReminders;
  List<EventBooking> get todayEvents => _todayEvents;
  double get totalIncome => _totalIncome;
  double get totalExpenses => _totalExpenses;
  double get netProfit => _totalIncome - _totalExpenses;
  double get totalBalancePending => _totalBalancePending;

  DateTime get selectedDate => _selectedDate;
  CalendarViewType get calendarView => _calendarView;
  int? get calendarHallFilter => _calendarHallFilter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Repositories access
  EnquiryRepository get enquiryRepo => _enquiryRepo;
  EventRepository get eventRepo => _eventRepo;
  HallRepository get hallRepo => _hallRepo;
  CustomerRepository get customerRepo => _customerRepo;
  PaymentRepository get paymentRepo => _paymentRepo;
  ExpenseRepository get expenseRepo => _expenseRepo;

  // Initialize and Seed
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await SampleData.seedIfEmpty();
      await refreshAll();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([
      loadEnquiries(),
      loadEvents(),
      loadHalls(),
      loadCustomers(),
      loadDashboardStats(),
    ]);
    notifyListeners();
  }

  // Enquiries Operations
  Future<void> loadEnquiries({String? searchQuery, String? statusFilter}) async {
    _enquiries = await _enquiryRepo.getEnquiries(
      searchQuery: searchQuery,
      statusFilter: statusFilter,
    );
    notifyListeners();
  }

  Future<void> saveEnquiry(Enquiry enquiry) async {
    if (enquiry.id == null) {
      await _enquiryRepo.insertEnquiry(enquiry);
    } else {
      await _enquiryRepo.updateEnquiry(enquiry);
    }
    await loadEnquiries();
    await loadDashboardStats();
  }

  Future<void> deleteEnquiry(int id) async {
    await _enquiryRepo.deleteEnquiry(id);
    await loadEnquiries();
    await loadDashboardStats();
  }

  Future<void> addFollowUpNote(FollowUp followUp) async {
    await _enquiryRepo.addFollowUp(followUp);
    await loadEnquiries();
    await loadDashboardStats();
  }

  Future<EventBooking> convertEnquiryToBooking({
    required Enquiry enquiry,
    required EventBooking eventData,
    double? initialAdvance,
    String? paymentMethod,
  }) async {
    final createdEvent = await _enquiryRepo.convertEnquiryToBooking(
      enquiry: enquiry,
      eventData: eventData,
      initialAdvance: initialAdvance,
      paymentMethod: paymentMethod,
    );
    await refreshAll();
    return createdEvent;
  }

  // Events Operations
  Future<void> loadEvents({
    String? searchQuery,
    String? statusFilter,
    int? hallIdFilter,
    DateTime? dateFilter,
  }) async {
    _events = await _eventRepo.getEvents(
      searchQuery: searchQuery,
      statusFilter: statusFilter,
      hallIdFilter: hallIdFilter,
      dateFilter: dateFilter,
    );
    notifyListeners();
  }

  Future<void> saveEvent(EventBooking event) async {
    if (event.id == null) {
      await _eventRepo.insertEvent(event);
    } else {
      await _eventRepo.updateEvent(event);
    }
    await loadEvents();
    await loadDashboardStats();
  }

  Future<void> cancelEvent(int id, {String? reason}) async {
    await _eventRepo.cancelEvent(id, reason: reason);
    await loadEvents();
    await loadDashboardStats();
  }

  Future<void> deleteEvent(int id) async {
    await _eventRepo.deleteEvent(id);
    await loadEvents();
    await loadDashboardStats();
  }

  // Halls Operations
  Future<void> loadHalls() async {
    _halls = await _hallRepo.getAllHalls();
    notifyListeners();
  }

  Future<void> saveHall(Hall hall) async {
    if (hall.id == null) {
      await _hallRepo.insertHall(hall);
    } else {
      await _hallRepo.updateHall(hall);
    }
    await loadHalls();
  }

  Future<void> deleteHall(int id) async {
    await _hallRepo.deleteHall(id);
    await loadHalls();
  }

  Future<HallAvailabilityResult> checkHallAvailability({
    required int hallId,
    required DateTime date,
    required String startTime,
    required String endTime,
    int? excludeEventId,
  }) async {
    return await _hallRepo.checkAvailability(
      hallId: hallId,
      date: date,
      startTime: startTime,
      endTime: endTime,
      excludeEventId: excludeEventId,
    );
  }

  // Customers Operations
  Future<void> loadCustomers({String? searchQuery}) async {
    _customers = await _customerRepo.getAllCustomers(searchQuery: searchQuery);
    notifyListeners();
  }

  Future<void> saveCustomer(Customer customer) async {
    if (customer.id == null) {
      await _customerRepo.insertCustomer(customer);
    } else {
      await _customerRepo.updateCustomer(customer);
    }
    await loadCustomers();
  }

  Future<void> deleteCustomer(int id) async {
    await _customerRepo.deleteCustomer(id);
    await loadCustomers();
  }

  // Financials & Payments
  Future<void> recordPayment(Payment payment) async {
    await _paymentRepo.insertPayment(payment);
    await refreshAll();
  }

  Future<void> deletePayment(int id, int eventId) async {
    await _paymentRepo.deletePayment(id, eventId);
    await refreshAll();
  }

  Future<void> recordExpense(Expense expense) async {
    if (expense.id == null) {
      await _expenseRepo.insertExpense(expense);
    } else {
      await _expenseRepo.updateExpense(expense);
    }
    await loadDashboardStats();
  }

  Future<void> deleteExpense(int id) async {
    await _expenseRepo.deleteExpense(id);
    await loadDashboardStats();
  }

  // Calendar Controls
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setCalendarView(CalendarViewType view) {
    _calendarView = view;
    notifyListeners();
  }

  void setCalendarHallFilter(int? hallId) {
    _calendarHallFilter = hallId;
    notifyListeners();
  }

  void goToToday() {
    _selectedDate = DateTime.now();
    notifyListeners();
  }

  void nextCalendarPeriod() {
    switch (_calendarView) {
      case CalendarViewType.month:
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
        break;
      case CalendarViewType.week:
        _selectedDate = _selectedDate.add(const Duration(days: 7));
        break;
      case CalendarViewType.day:
      case CalendarViewType.agenda:
        _selectedDate = _selectedDate.add(const Duration(days: 1));
        break;
    }
    notifyListeners();
  }

  void prevCalendarPeriod() {
    switch (_calendarView) {
      case CalendarViewType.month:
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
        break;
      case CalendarViewType.week:
        _selectedDate = _selectedDate.subtract(const Duration(days: 7));
        break;
      case CalendarViewType.day:
      case CalendarViewType.agenda:
        _selectedDate = _selectedDate.subtract(const Duration(days: 1));
        break;
    }
    notifyListeners();
  }

  // Dashboard Stats
  Future<void> loadDashboardStats() async {
    final now = DateTime.now();
    _followUpReminders = await _enquiryRepo.getFollowUpReminders(date: now);

    final todayStr = DateFormatters.formatIsoDate(now);
    _todayEvents = _events.where((e) {
      return DateFormatters.formatIsoDate(e.eventDate) == todayStr && e.status != 'Cancelled';
    }).toList();

    _totalIncome = await _paymentRepo.getTotalIncome();
    _totalExpenses = await _expenseRepo.getTotalExpenses();
    _totalBalancePending = await _paymentRepo.getTotalPendingBalances();
  }
}

