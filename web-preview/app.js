/**
 * Event & Venue Management System - Web Preview
 * Complete interactive frontend mirroring Flutter SQLite application
 */

// Initial Seed Data - Empty Clean Slate
const INITIAL_DATA = {
  halls: [],
  customers: [],
  enquiries: [],
  followUps: [],
  events: [],
  payments: [],
  expenses: [],
  holds: []
};

// State Store with localStorage persistence
class Store {
  constructor() {
    this.data = this.load();
    this.currentTab = 'dashboard';
    this.selectedCalendarDate = new Date();
    this.calendarView = 'month'; // month, week, day, agenda
    this.calendarHallFilter = null;
    this.customerSearch = '';
    this.enquirySearch = '';
    this.enquiryStatusFilter = 'All';
    this.eventSearch = '';
    this.eventStatusFilter = 'All';
    this.eventHallFilter = null;
    this.activeModal = null;
    this.currentDetailItem = null;
  }

  load() {
    const saved = localStorage.getItem('venue_master_data');
    if (saved) {
      try {
        const parsed = JSON.parse(saved);
        // Clear if old dummy demo records exist
        if (parsed.enquiries && parsed.enquiries.some(e => e.customerName === 'ABC XD')) {
          localStorage.removeItem('venue_master_data');
          return JSON.parse(JSON.stringify(INITIAL_DATA));
        }
        return parsed;
      } catch (e) { }
    }
    return JSON.parse(JSON.stringify(INITIAL_DATA));
  }

  save() {
    localStorage.setItem('venue_master_data', JSON.stringify(this.data));
  }

  reset() {
    this.data = JSON.parse(JSON.stringify(INITIAL_DATA));
    this.save();
  }
}

const store = new Store();

// Currency and Date Formatters
function formatCurrency(amount) {
  return '₹' + Number(amount || 0).toLocaleString('en-IN');
}

function formatDate(isoStr) {
  if (!isoStr) return '-';
  const d = new Date(isoStr);
  if (isNaN(d)) return isoStr;
  const day = String(d.getDate()).padStart(2, '0');
  const month = String(d.getMonth() + 1).padStart(2, '0');
  const year = d.getFullYear();
  return `${day}/${month}/${year}`;
}

function formatDateShort(isoStr) {
  if (!isoStr) return '-';
  const d = new Date(isoStr);
  return d.toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });
}

function getStatusBadgeClass(status) {
  switch ((status || '').toLowerCase()) {
    case 'confirmed': return 'bg-emerald-100 text-emerald-800';
    case 'follow-up': return 'bg-amber-100 text-amber-800';
    case 'new': return 'bg-blue-100 text-blue-800';
    case 'closed': return 'bg-slate-200 text-slate-700';
    default: return 'bg-slate-100 text-slate-700';
  }
}

// Navigation Definition
const NAV_ITEMS = [
  { id: 'dashboard', label: 'Dashboard', icon: 'fa-solid fa-chart-pie' },
  { id: 'enquiries', label: 'Enquiries', icon: 'fa-solid fa-address-book', badgeKey: 'followUpsDue' },
  { id: 'calendar', label: 'Calendar', icon: 'fa-solid fa-calendar-days' },
  { id: 'events', label: 'Events', icon: 'fa-solid fa-calendar-check' },
  { id: 'customers', label: 'Customers', icon: 'fa-solid fa-users' },
  { id: 'finance', label: 'Finance & Reports', icon: 'fa-solid fa-file-invoice-dollar' }
];

// Initialize UI
document.addEventListener('DOMContentLoaded', () => {
  renderSidebar();
  renderMobileNav();
  switchTab('dashboard');
});

function renderSidebar() {
  const container = document.getElementById('desktopNav');
  const followUpsDueCount = getFollowUpsDueToday().length;

  container.innerHTML = NAV_ITEMS.map(item => {
    const isActive = store.currentTab === item.id;
    const hasBadge = item.badgeKey === 'followUpsDue' && followUpsDueCount > 0;

    return `
      <button onclick="switchTab('${item.id}')" class="w-full flex items-center justify-between px-3.5 py-2.5 rounded-xl font-semibold text-xs transition ${isActive ? 'bg-brand text-white shadow-sm shadow-blue-200' : 'text-slate-600 hover:bg-slate-100'
      }">
        <div class="flex items-center gap-3">
          <i class="${item.icon} text-sm w-4"></i>
          <span>${item.label}</span>
        </div>
        ${hasBadge ? `<span class="px-1.5 py-0.5 rounded-full text-[10px] font-bold ${isActive ? 'bg-white text-brand' : 'bg-amber-500 text-white'}">${followUpsDueCount}</span>` : ''}
      </button>
    `;
  }).join('');
}

function renderMobileNav() {
  const container = document.getElementById('mobileNav');
  const followUpsDueCount = getFollowUpsDueToday().length;

  container.innerHTML = NAV_ITEMS.map(item => {
    const isActive = store.currentTab === item.id;
    return `
      <button onclick="switchTab('${item.id}')" class="flex flex-col items-center justify-center p-1.5 flex-1 relative ${
        isActive ? 'text-brand font-bold' : 'text-slate-500 font-medium'
      }">
        <i class="${item.icon} text-lg mb-0.5"></i>
        <span class="text-[10px]">${item.label}</span>
        ${item.badgeKey === 'followUpsDue' && followUpsDueCount > 0 ? `
          <span class="absolute top-1 right-3 w-2 h-2 rounded-full bg-amber-500"></span>
        ` : ''}
      </button>
    `;
  }).join('');
}

function switchTab(tabId) {
  store.currentTab = tabId;
  const navItem = NAV_ITEMS.find(i => i.id === tabId);
  document.getElementById('currentSectionTitle').innerText = navItem ? navItem.label : 'Event Manager';
  renderSidebar();
  renderMobileNav();
  renderSectionContent(tabId);
}

function renderSectionContent(tabId) {
  const viewport = document.getElementById('contentViewport');
  switch (tabId) {
    case 'dashboard':
      viewport.innerHTML = renderDashboardView();
      break;
    case 'enquiries':
      viewport.innerHTML = renderEnquiriesView();
      break;
    case 'calendar':
      viewport.innerHTML = renderCalendarView();
      break;
    case 'events':
      viewport.innerHTML = renderEventsView();
      break;
    case 'customers':
      viewport.innerHTML = renderCustomersView();
      break;
    case 'finance':
      viewport.innerHTML = renderFinanceView();
      break;
  }
}

// -------------------------------------------------------------
// 1. DASHBOARD VIEW
// -------------------------------------------------------------
function getFollowUpsDueToday() {
  return store.data.enquiries.filter(e => e.status === 'Follow-up');
}

function renderDashboardView() {
  const totalRevenue = store.data.payments.reduce((acc, p) => acc + Number(p.amount), 0);
  const totalExpenses = store.data.expenses.reduce((acc, e) => acc + Number(e.amount), 0);
  const pendingBalance = store.data.events
    .filter(e => e.status === 'Confirmed')
    .reduce((acc, e) => acc + Number(e.balanceDue), 0);
  const netProfit = totalRevenue - totalExpenses;
  const activeEnquiries = store.data.enquiries.filter(e => e.status !== 'Closed');
  const followUpsDue = getFollowUpsDueToday();
  const confirmedEvents = store.data.events.filter(e => e.status === 'Confirmed');

  return `
    <div class="space-y-6 max-w-7xl mx-auto">
      <!-- 4 KPI Cards -->
      <div class="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <div class="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex flex-col justify-between">
          <div class="flex items-center justify-between text-xs text-slate-500 font-semibold mb-2">
            <span>Total Collected</span>
            <div class="w-8 h-8 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center text-sm"><i class="fa-solid fa-wallet"></i></div>
          </div>
          <div class="text-xl font-bold text-emerald-600 font-mono">${formatCurrency(totalRevenue)}</div>
          <div class="text-[11px] text-slate-400 mt-1">Across all bookings</div>
        </div>

        <div class="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex flex-col justify-between">
          <div class="flex items-center justify-between text-xs text-slate-500 font-semibold mb-2">
            <span>Pending Balances</span>
            <div class="w-8 h-8 rounded-full bg-rose-50 text-rose-600 flex items-center justify-center text-sm"><i class="fa-solid fa-clock"></i></div>
          </div>
          <div class="text-xl font-bold text-rose-600 font-mono">${formatCurrency(pendingBalance)}</div>
          <div class="text-[11px] text-slate-400 mt-1">To collect before events</div>
        </div>

        <div class="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex flex-col justify-between">
          <div class="flex items-center justify-between text-xs text-slate-500 font-semibold mb-2">
            <span>Net Operating Profit</span>
            <div class="w-8 h-8 rounded-full bg-blue-50 text-brand flex items-center justify-center text-sm"><i class="fa-solid fa-arrow-trend-up"></i></div>
          </div>
          <div class="text-xl font-bold text-brand font-mono">${formatCurrency(netProfit)}</div>
          <div class="text-[11px] text-slate-400 mt-1">After ${formatCurrency(totalExpenses)} expenses</div>
        </div>

        <div class="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex flex-col justify-between">
          <div class="flex items-center justify-between text-xs text-slate-500 font-semibold mb-2">
            <span>Active Enquiries</span>
            <div class="w-8 h-8 rounded-full bg-purple-50 text-purple-600 flex items-center justify-center text-sm"><i class="fa-solid fa-phone"></i></div>
          </div>
          <div class="text-xl font-bold text-purple-700">${activeEnquiries.length} Leads</div>
          <div class="text-[11px] text-slate-400 mt-1">${confirmedEvents.length} confirmed bookings</div>
        </div>
      </div>

      <!-- Quick Action Row -->
      <div class="flex items-center gap-2 overflow-x-auto pb-1">
        <button onclick="openModal('addEnquiryModal')" class="py-2 px-3.5 bg-white border border-slate-300 hover:border-brand text-slate-700 rounded-xl text-xs font-bold flex items-center gap-2 shadow-sm whitespace-nowrap">
          <i class="fa-solid fa-user-plus text-brand"></i> New Enquiry
        </button>
        <button onclick="openModal('addEventModal')" class="py-2 px-3.5 bg-white border border-slate-300 hover:border-emerald-600 text-slate-700 rounded-xl text-xs font-bold flex items-center gap-2 shadow-sm whitespace-nowrap">
          <i class="fa-solid fa-calendar-plus text-emerald-600"></i> Book Event
        </button>
        <button onclick="switchTab('calendar')" class="py-2 px-3.5 bg-white border border-slate-300 hover:border-blue-500 text-slate-700 rounded-xl text-xs font-bold flex items-center gap-2 shadow-sm whitespace-nowrap">
          <i class="fa-solid fa-calendar-days text-blue-500"></i> Google Calendar
        </button>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <!-- Follow-up Reminders Alert Section -->
        <div class="bg-white rounded-2xl border border-slate-200 p-5 shadow-sm">
          <div class="flex items-center justify-between mb-4">
            <div class="flex items-center gap-2">
              <i class="fa-solid fa-bell text-amber-500 text-base"></i>
              <h3 class="font-bold text-sm text-slate-900">Follow-up Reminders</h3>
            </div>
            <span class="text-xs px-2.5 py-0.5 rounded-full font-bold bg-amber-100 text-amber-800">${followUpsDue.length} Due</span>
          </div>

          ${followUpsDue.length === 0 ? `
            <div class="p-6 text-center text-xs text-slate-400 bg-slate-50 rounded-xl">
              No follow-ups due today. You are completely caught up!
            </div>
          ` : `
            <div class="space-y-2.5">
              ${followUpsDue.map(enq => `
                <div class="p-3 bg-amber-50/60 border border-amber-200/60 rounded-xl flex items-center justify-between">
                  <div onclick="openEnquiryDetail(${enq.id})" class="cursor-pointer">
                    <div class="font-bold text-xs text-slate-900">${enq.customerName} <span class="font-normal text-slate-500">(${enq.eventType})</span></div>
                    <div class="text-[11px] text-slate-600 mt-0.5">Pref: ${formatDate(enq.preferredDate)} • Budget: ${formatCurrency(enq.expectedBudget)}</div>
                  </div>
                  <div class="flex items-center gap-1.5">
                    <a href="tel:${enq.phone}" class="p-2 text-brand hover:bg-white rounded-lg"><i class="fa-solid fa-phone text-xs"></i></a>
                    <button onclick="openEnquiryDetail(${enq.id})" class="text-xs font-bold py-1 px-2.5 bg-brand text-white rounded-lg">View</button>
                  </div>
                </div>
              `).join('')}
            </div>
          `}
        </div>

        <!-- Confirmed Events Schedule -->
        <div class="bg-white rounded-2xl border border-slate-200 p-5 shadow-sm">
          <div class="flex items-center justify-between mb-4">
            <div class="flex items-center gap-2">
              <i class="fa-solid fa-calendar-check text-emerald-600 text-base"></i>
              <h3 class="font-bold text-sm text-slate-900">Upcoming Confirmed Events</h3>
            </div>
            <button onclick="switchTab('calendar')" class="text-xs text-brand font-semibold hover:underline">View Calendar</button>
          </div>

          <div class="space-y-2.5">
            ${confirmedEvents.map(evt => `
              <div onclick="openEventDetail(${evt.id})" class="p-3 bg-slate-50 hover:bg-blue-50/50 border border-slate-200 rounded-xl cursor-pointer transition flex items-center justify-between">
                <div>
                  <div class="font-bold text-xs text-slate-900">${evt.customerName} - ${evt.eventType}</div>
                  <div class="text-[11px] text-slate-500 mt-0.5">${(evt.hallName || 'Venue').split('(')[0]} • ${formatDate(evt.eventDate)} (${evt.startTime} – ${evt.endTime})</div>
                </div>
                <div class="text-right">
                  <div class="font-bold text-xs text-slate-800 font-mono">${formatCurrency(evt.totalCost)}</div>
                  <div class="text-[10px] text-slate-400">${evt.balanceDue > 0 ? `Due: ${formatCurrency(evt.balanceDue)}` : 'Fully Paid'}</div>
                </div>
              </div>
            `).join('')}
          </div>
        </div>
      </div>
    </div>
  `;
}

// -------------------------------------------------------------
// 2. ENQUIRY MANAGEMENT VIEW
// -------------------------------------------------------------
function renderEnquiriesView() {
  const statusOptions = ['All', 'New', 'Follow-up', 'Confirmed', 'Closed'];
  let list = store.data.enquiries;

  if (store.enquirySearch) {
    const q = store.enquirySearch.toLowerCase();
    list = list.filter(e => e.customerName.toLowerCase().includes(q) || e.phone.includes(q) || e.enquiryNumber.toLowerCase().includes(q));
  }

  if (store.enquiryStatusFilter !== 'All') {
    list = list.filter(e => e.status === store.enquiryStatusFilter);
  }

  return `
    <div class="space-y-4 max-w-7xl mx-auto">
      <!-- Toolbar -->
      <div class="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm">
        <div class="flex flex-col sm:flex-row gap-3 items-center justify-between">
          <div class="flex flex-col sm:flex-row gap-2.5 w-full sm:w-auto flex-1 items-stretch sm:items-center">
            <div class="relative flex-1">
              <i class="fa-solid fa-search absolute left-3.5 top-3 text-slate-400 text-xs"></i>
              <input type="text" placeholder="Search customer, phone, enquiry #..." value="${store.enquirySearch}" oninput="setEnquirySearch(this.value)" class="w-full pl-9 pr-3 py-2 text-xs border border-slate-200 rounded-xl focus:ring-2 focus:ring-brand outline-none">
            </div>
            <div class="flex items-center gap-2">
              <span class="text-xs font-semibold text-slate-500 whitespace-nowrap">Filter:</span>
              <select onchange="setEnquiryStatusFilter(this.value)" class="py-2 px-3 text-xs border border-slate-200 rounded-xl bg-white font-semibold text-slate-700 focus:ring-2 focus:ring-brand outline-none">
                ${statusOptions.map(st => `
                  <option value="${st}" ${store.enquiryStatusFilter === st ? 'selected' : ''}>${st === 'All' ? 'All Enquiries' : st}</option>
                `).join('')}
              </select>
            </div>
          </div>
          <button onclick="openModal('addEnquiryModal')" class="w-full sm:w-auto py-2 px-4 bg-brand hover:bg-brandDark text-white font-bold text-xs rounded-xl shadow-sm flex items-center justify-center gap-2 whitespace-nowrap transition">
            <i class="fa-solid fa-plus"></i> Add New Enquiry
          </button>
        </div>
      </div>

      <!-- Enquiries Card List -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        ${list.length === 0 ? `
          <div class="col-span-1 md:col-span-2 p-12 text-center bg-white rounded-2xl border border-slate-200">
            <i class="fa-solid fa-address-book text-slate-300 text-4xl mb-3"></i>
            <h4 class="font-bold text-slate-700 text-sm">No enquiries found</h4>
            <p class="text-xs text-slate-400 mt-1">Click "Add New Enquiry" to add customer enquiries.</p>
          </div>
        ` : list.map(enq => {
      const isConverted = Boolean(enq.convertedEventId || enq.status === 'Confirmed');
      return `
            <div class="bg-white rounded-2xl border border-slate-200 p-5 shadow-sm hover:border-blue-300 transition flex flex-col justify-between">
              <div>
                <div class="flex items-start justify-between gap-2 mb-2">
                  <div>
                    <h4 onclick="openEnquiryDetail(${enq.id})" class="font-bold text-base text-slate-900 cursor-pointer hover:text-brand transition">${enq.customerName}</h4>
                    <span class="text-xs font-semibold text-brand">${enq.enquiryNumber}</span>
                  </div>
                  <span class="text-xs px-2.5 py-0.5 rounded-full font-bold ${getStatusBadgeClass(enq.status)}">${enq.status}</span>
                </div>

                <div class="grid grid-cols-2 gap-2 text-xs text-slate-600 my-3 bg-slate-50 p-3 rounded-xl">
                  <div><span class="text-slate-400 block text-[11px]">Event:</span> <strong class="text-slate-800">${enq.eventType}</strong> (${enq.guests} pax)</div>
                  <div><span class="text-slate-400 block text-[11px]">Expected Budget:</span> <span class="font-bold text-emerald-600">${formatCurrency(enq.expectedBudget)}</span></div>
                  <div class="col-span-2"><span class="text-slate-400 block text-[11px]">Date & Time:</span> ${formatDate(enq.preferredDate)} • ${enq.preferredTime}</div>
                </div>
              </div>

              <div class="pt-3 border-t border-slate-100 flex items-center justify-between">
                <a href="tel:${enq.phone}" class="text-xs font-bold text-brand hover:underline flex items-center gap-1">
                  <i class="fa-solid fa-phone"></i> ${enq.phone}
                </a>

                <div class="flex items-center gap-2">
                  <button onclick="openEnquiryDetail(${enq.id})" class="text-xs font-semibold py-1.5 px-3 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-lg">
                    Details
                  </button>
                  ${!isConverted ? `
                    <button onclick="openConvertModal(${enq.id})" class="text-xs font-bold py-1.5 px-3 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg flex items-center gap-1">
                      <i class="fa-solid fa-check"></i> Convert
                    </button>
                  ` : `
                    <span class="text-xs font-semibold text-emerald-700 flex items-center gap-1">
                      <i class="fa-solid fa-circle-check"></i> Converted
                    </span>
                  `}
                </div>
              </div>
            </div>
          `;
    }).join('')}
      </div>
    </div>
  `;
}

function setEnquirySearch(val) {
  store.enquirySearch = val;
  renderSectionContent('enquiries');
}

function setEnquiryStatusFilter(val) {
  store.enquiryStatusFilter = val;
  renderSectionContent('enquiries');
}

// -------------------------------------------------------------
// 3. GOOGLE CALENDAR STYLE SCHEDULE VIEW
// -------------------------------------------------------------
function renderCalendarView() {
  const selDate = store.selectedCalendarDate;
  const currentMonthYear = selDate.toLocaleDateString('en-IN', { month: 'long', year: 'numeric' });
  const view = store.calendarView;

  let calendarEvents = store.data.events.filter(e => e.status !== 'Cancelled');

  return `
    <div class="h-full flex flex-col space-y-3 max-w-7xl mx-auto">
      <!-- Calendar Controls Header -->
      <div class="bg-white p-3.5 rounded-2xl border border-slate-200 shadow-sm flex flex-col sm:flex-row items-center justify-between gap-3">
        <div class="flex items-center gap-3 w-full sm:w-auto justify-between">
          <div class="flex items-center gap-2">
            <h3 class="text-lg font-bold text-slate-900">${currentMonthYear}</h3>
            <button onclick="promptJumpToDate()" class="text-xs text-brand p-1 hover:bg-blue-50 rounded"><i class="fa-solid fa-calendar-day"></i></button>
          </div>
          <div class="flex items-center gap-1">
            <button onclick="changeCalendarPeriod(-1)" class="w-8 h-8 rounded-lg border border-slate-200 hover:bg-slate-100 flex items-center justify-center text-xs"><i class="fa-solid fa-chevron-left"></i></button>
            <button onclick="goToCalendarToday()" class="px-2.5 py-1 text-xs font-bold border border-slate-200 hover:bg-slate-100 rounded-lg">Today</button>
            <button onclick="changeCalendarPeriod(1)" class="w-8 h-8 rounded-lg border border-slate-200 hover:bg-slate-100 flex items-center justify-center text-xs"><i class="fa-solid fa-chevron-right"></i></button>
          </div>
        </div>

        <div class="flex items-center gap-2 w-full sm:w-auto justify-end">
          <!-- View Switcher -->
          <div class="bg-slate-100 p-1 rounded-xl flex items-center gap-1 text-xs font-bold">
            <button onclick="setCalendarView('month')" class="py-1 px-2.5 rounded-lg ${view === 'month' ? 'bg-white shadow-sm text-brand' : 'text-slate-600'}">Month</button>
            <button onclick="setCalendarView('week')" class="py-1 px-2.5 rounded-lg ${view === 'week' ? 'bg-white shadow-sm text-brand' : 'text-slate-600'}">Week</button>
            <button onclick="setCalendarView('day')" class="py-1 px-2.5 rounded-lg ${view === 'day' ? 'bg-white shadow-sm text-brand' : 'text-slate-600'}">Day</button>
            <button onclick="setCalendarView('agenda')" class="py-1 px-2.5 rounded-lg ${view === 'agenda' ? 'bg-white shadow-sm text-brand' : 'text-slate-600'}">Agenda</button>
          </div>
        </div>
      </div>

      <!-- Main Calendar Grid Area -->
      <div class="flex-1 bg-white rounded-2xl border border-slate-200 shadow-sm flex flex-col overflow-hidden min-h-[500px]">
        ${view === 'month' ? renderMonthGrid(calendarEvents) : ''}
        ${view === 'week' ? renderWeekGrid(calendarEvents) : ''}
        ${view === 'day' ? renderDayGrid(calendarEvents) : ''}
        ${view === 'agenda' ? renderAgendaGrid(calendarEvents) : ''}
      </div>
    </div>
  `;
}

function renderMonthGrid(events) {
  const selDate = store.selectedCalendarDate;
  const year = selDate.getFullYear();
  const month = selDate.getMonth();
  const firstDayIndex = new Date(year, month, 1).getDay(); // Sun = 0
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const daysInPrevMonth = new Date(year, month, 0).getDate();
  const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  // Events on currently active selected day for the bottom inspector
  const selDateIso = selDate.toISOString().split('T')[0];
  const activeDayEvents = events.filter(e => e.eventDate === selDateIso);

  let gridCells = [];
  for (let i = 0; i < 42; i++) {
    const dayNum = i - firstDayIndex + 1;
    let cellDate;
    let isCurrentMonth = true;

    if (dayNum < 1) {
      cellDate = new Date(year, month - 1, daysInPrevMonth + dayNum);
      isCurrentMonth = false;
    } else if (dayNum > daysInMonth) {
      cellDate = new Date(year, month + 1, dayNum - daysInMonth);
      isCurrentMonth = false;
    } else {
      cellDate = new Date(year, month, dayNum);
    }

    const cellIso = cellDate.toISOString().split('T')[0];
    const cellEvents = events.filter(e => e.eventDate === cellIso);
    const isToday = new Date().toISOString().split('T')[0] === cellIso;
    const isSelected = selDateIso === cellIso;

    gridCells.push(`
      <div onclick="selectCalendarDate('${cellIso}')" class="min-h-[70px] sm:min-h-[85px] p-1.5 border-b border-r border-slate-100 flex flex-col justify-between transition cursor-pointer ${isSelected ? 'bg-blue-50/50' : 'hover:bg-slate-50'
      } ${!isCurrentMonth ? 'opacity-40' : ''}">
        <div class="flex items-center justify-between">
          <span class="text-xs font-semibold w-6 h-6 rounded-full flex items-center justify-center ${isToday ? 'bg-brand text-white font-bold' : isSelected ? 'bg-blue-200 text-brand font-bold' : 'text-slate-700'
      }">${cellDate.getDate()}</span>
        </div>

        <div class="space-y-1 mt-1 overflow-hidden">
          ${cellEvents.slice(0, 2).map(ev => `
            <div onclick="event.stopPropagation(); openEventDetail(${ev.id})" class="text-[10px] font-bold py-0.5 px-1.5 rounded truncate bg-emerald-600 text-white shadow-xs">
              ${ev.startTime ? ev.startTime.split(' ')[0] : ''} ${ev.eventType}
            </div>
          `).join('')}
          ${cellEvents.length > 2 ? `<div class="text-[9px] text-slate-400 font-bold">+${cellEvents.length - 2} more</div>` : ''}
        </div>
      </div>
    `);
  }

  return `
    <div class="flex-1 flex flex-col">
      <!-- Weekday headers -->
      <div class="grid grid-cols-7 border-b border-slate-200 bg-slate-50 text-center py-2 text-xs font-bold text-slate-600">
        ${weekdays.map(d => `<div>${d}</div>`).join('')}
      </div>

      <!-- 7x6 Day Cells -->
      <div class="grid grid-cols-7 flex-1 border-l border-t border-slate-100">
        ${gridCells.join('')}
      </div>

      <!-- Selected Date Detail Drawer (Directly matches Google Calendar UX requirement) -->
      <div class="border-t border-slate-200 p-4 bg-slate-50">
        <div class="flex items-center justify-between mb-3">
          <h4 class="text-xs font-bold text-slate-800 uppercase tracking-wider">
            Bookings for ${formatDateShort(selDateIso)}
          </h4>
          <button onclick="openModal('addEventModal')" class="text-xs text-brand font-bold hover:underline">+ Schedule Event</button>
        </div>

        ${activeDayEvents.length === 0 ? `
          <div class="text-xs text-slate-400 py-2">No bookings scheduled on this day. Tap any slot or "+ Schedule Event" to add.</div>
        ` : `
          <div class="grid grid-cols-1 md:grid-cols-2 gap-3">

            ${activeDayEvents.map(evt => `
              <div onclick="openEventDetail(${evt.id})" class="bg-white border border-slate-200 hover:border-brand p-3 rounded-xl shadow-xs flex items-center justify-between cursor-pointer transition">
                <div>
                  <div class="flex items-center gap-2">
                    <span class="font-bold text-xs text-slate-900">${evt.customerName}</span>
                    <span class="text-[10px] px-2 py-0.5 rounded-full font-bold bg-emerald-100 text-emerald-800">Confirmed</span>
                  </div>
                  <div class="text-[11px] text-slate-600 mt-0.5">${evt.eventType} • ${(evt.hallName || 'Venue').split('(')[0]} (${evt.startTime} – ${evt.endTime})</div>
                  <div class="text-[11px] font-bold text-brand mt-1">${formatCurrency(evt.totalCost)}</div>
                </div>
                <i class="fa-solid fa-chevron-right text-xs text-slate-400"></i>
              </div>
            `).join('')}
          </div>
        `}
      </div>
    </div>
  `;
}

function renderWeekGrid(events) {
  const selDate = store.selectedCalendarDate;
  const startOfWeek = new Date(selDate);
  startOfWeek.setDate(selDate.getDate() - selDate.getDay()); // Sunday

  const weekDays = Array.from({ length: 7 }, (_, i) => {
    const d = new Date(startOfWeek);
    d.setDate(startOfWeek.getDate() + i);
    return d;
  });

  return `
    <div class="flex-1 grid grid-cols-7 divide-x divide-slate-200 overflow-y-auto custom-scrollbar">
      ${weekDays.map(day => {
    const iso = day.toISOString().split('T')[0];
    const dayEvents = events.filter(e => e.eventDate === iso);
    return `
          <div class="flex flex-col min-h-[350px]">
            <div class="p-2 border-b border-slate-200 text-center bg-slate-50">
              <div class="text-[11px] text-slate-500 font-semibold">${day.toLocaleDateString('en-IN', { weekday: 'short' })}</div>
              <div class="text-sm font-bold text-slate-800">${day.getDate()}</div>
            </div>
            <div class="p-2 flex-1 space-y-2">
              ${dayEvents.map(ev => `
                <div onclick="openEventDetail(${ev.id})" class="p-2 bg-blue-50 border border-blue-200 rounded-lg text-xs cursor-pointer hover:bg-blue-100 transition">
                  <div class="font-bold text-brand truncate">${ev.eventType}</div>
                  <div class="text-[11px] text-slate-700 truncate">${ev.customerName}</div>
                  <div class="text-[10px] text-slate-500">${ev.startTime}</div>
                </div>
              `).join('')}
            </div>
          </div>
        `;
  }).join('')}
    </div>
  `;
}

function renderDayGrid(events) {
  const selDateIso = store.selectedCalendarDate.toISOString().split('T')[0];
  const dayEvents = events.filter(e => e.eventDate === selDateIso);

  return `
    <div class="p-6 flex-1 overflow-y-auto">
      <div class="flex items-center justify-between mb-4">
        <h3 class="font-bold text-base text-slate-900">${formatDateShort(selDateIso)} Schedule</h3>
        <button onclick="openModal('addEventModal')" class="py-1.5 px-3 bg-brand text-white font-bold text-xs rounded-lg">+ Add Booking</button>
      </div>

      ${dayEvents.length === 0 ? `
        <div class="p-12 text-center text-slate-400 text-xs">No bookings for this date. The venue is completely free.</div>
      ` : `
        <div class="space-y-3">
          ${dayEvents.map(ev => `
            <div onclick="openEventDetail(${ev.id})" class="p-4 bg-white border border-slate-200 hover:border-brand rounded-2xl shadow-xs cursor-pointer flex items-center justify-between transition">
              <div>
                <div class="flex items-center gap-2">
                  <h4 class="font-bold text-sm text-slate-900">${ev.eventType} - ${ev.customerName}</h4>
                  <span class="text-xs px-2 py-0.5 rounded-full font-bold bg-emerald-100 text-emerald-800">Confirmed</span>
                </div>
                <p class="text-xs text-slate-600 mt-1">${ev.hallName ? ev.hallName + ' • ' : ''}${ev.startTime} – ${ev.endTime} • ${ev.guests} Guests</p>
                <p class="text-xs font-bold text-brand mt-1 font-mono">${formatCurrency(ev.totalCost)} (Balance: ${formatCurrency(ev.balanceDue)})</p>
              </div>
              <button class="text-xs font-bold py-2 px-3.5 bg-slate-100 hover:bg-slate-200 rounded-lg">View Popup</button>
            </div>
          `).join('')}
        </div>
      `}
    </div>
  `;
}

function renderAgendaGrid(events) {
  const sorted = [...events].sort((a, b) => new Date(a.eventDate) - new Date(b.eventDate));
  return `
    <div class="p-6 flex-1 overflow-y-auto space-y-3">
      ${sorted.map(ev => `
        <div onclick="openEventDetail(${ev.id})" class="p-4 bg-white border border-slate-200 hover:border-brand rounded-2xl shadow-xs flex items-center justify-between cursor-pointer transition">
          <div class="flex items-center gap-4">
            <div class="text-center w-12 bg-slate-100 p-2 rounded-xl">
              <span class="text-xs block text-slate-500 font-bold uppercase">${new Date(ev.eventDate).toLocaleDateString('en-IN', { month: 'short' })}</span>
              <span class="text-lg font-bold text-brand">${new Date(ev.eventDate).getDate()}</span>
            </div>
            <div>
              <h4 class="font-bold text-xs text-slate-900">${ev.customerName} - ${ev.eventType}</h4>
              <p class="text-[11px] text-slate-500">${(ev.hallName || 'Venue').split('(')[0]} • ${ev.startTime} – ${ev.endTime}</p>
            </div>
          </div>
          <div class="font-bold text-xs text-slate-900 font-mono">${formatCurrency(ev.totalCost)}</div>
        </div>
      `).join('')}
    </div>
  `;
}

function changeCalendarPeriod(delta) {
  const d = new Date(store.selectedCalendarDate);
  if (store.calendarView === 'month') {
    d.setMonth(d.getMonth() + delta);
  } else if (store.calendarView === 'week') {
    d.setDate(d.getDate() + (delta * 7));
  } else {
    d.setDate(d.getDate() + delta);
  }
  store.selectedCalendarDate = d;
  renderSectionContent('calendar');
}

function goToCalendarToday() {
  store.selectedCalendarDate = new Date();
  renderSectionContent('calendar');
}

function setCalendarView(v) {
  store.calendarView = v;
  renderSectionContent('calendar');
}

function setCalendarHallFilter(val) {
  store.calendarHallFilter = val ? Number(val) : null;
  renderSectionContent('calendar');
}

function selectCalendarDate(isoStr) {
  store.selectedCalendarDate = new Date(isoStr);
  renderSectionContent('calendar');
}

function promptJumpToDate() {
  const chosen = prompt("Enter target date (YYYY-MM-DD):", new Date().toISOString().split('T')[0]);
  if (chosen && !isNaN(new Date(chosen))) {
    store.selectedCalendarDate = new Date(chosen);
    renderSectionContent('calendar');
  }
}

// -------------------------------------------------------------
// 4. CONFIRMED EVENTS VIEW
// -------------------------------------------------------------
function renderEventsView() {
  let list = store.data.events;

  if (store.eventSearch) {
    const q = store.eventSearch.toLowerCase();
    list = list.filter(e => e.customerName.toLowerCase().includes(q) || e.eventNumber.toLowerCase().includes(q) || e.eventType.toLowerCase().includes(q));
  }

  return `
    <div class="space-y-4 max-w-7xl mx-auto">
      <div class="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex flex-col sm:flex-row gap-3 items-center justify-between">
        <div class="relative w-full sm:w-80">
          <i class="fa-solid fa-search absolute left-3.5 top-3 text-slate-400 text-xs"></i>
          <input type="text" placeholder="Search bookings by customer, event #..." value="${store.eventSearch}" oninput="store.eventSearch = this.value; renderSectionContent('events')" class="w-full pl-9 pr-3 py-2 text-xs border border-slate-200 rounded-xl focus:ring-2 focus:ring-brand outline-none">
        </div>
        <button onclick="openModal('addEventModal')" class="w-full sm:w-auto py-2 px-4 bg-emerald-600 text-white font-bold text-xs rounded-xl shadow-sm flex items-center justify-center gap-2">
          <i class="fa-solid fa-plus"></i> New Confirmed Booking
        </button>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        ${list.length === 0 ? `
          <div class="col-span-full py-12 text-center bg-white rounded-2xl border border-slate-200 shadow-sm">
            <i class="fa-solid fa-calendar-xmark text-4xl text-slate-300 mb-3 block"></i>
            <h4 class="text-sm font-bold text-slate-700">No bookings found</h4>
            <p class="text-xs text-slate-400 mt-1">No bookings match your current search criteria.</p>
          </div>
        ` : list.map(ev => `
          <div onclick="openEventDetail(${ev.id})" class="bg-white rounded-2xl border border-slate-200 p-5 shadow-sm hover:border-emerald-400 transition cursor-pointer flex flex-col justify-between">
            <div>
              <div class="flex items-start justify-between gap-2 mb-2">
                <div>
                  <h4 class="font-bold text-base text-slate-900">${ev.customerName}</h4>
                  <span class="text-xs font-semibold text-brand">${ev.eventNumber} • ${ev.phone}</span>
                </div>
                <span class="text-xs px-2.5 py-0.5 rounded-full font-bold ${getStatusBadgeClass(ev.status)}">${ev.status}</span>
              </div>

              <div class="grid grid-cols-2 gap-2 text-xs text-slate-600 my-3 bg-slate-50 p-3 rounded-xl">
                <div><span class="text-slate-400 block text-[11px]">Event Type:</span> <strong>${ev.eventType}</strong> (${ev.guests} pax)</div>
                <div><span class="text-slate-400 block text-[11px]">Event Date:</span> ${formatDate(ev.eventDate)}</div>
                <div class="col-span-2"><span class="text-slate-400 block text-[11px]">Timings:</span> ${ev.startTime} – ${ev.endTime}</div>
              </div>
            </div>

            <div class="pt-3 border-t border-slate-100 flex items-center justify-between text-xs">
              <div>
                <span class="text-slate-400 block text-[10px]">Agreed Total</span>
                <span class="font-bold text-slate-900 font-mono text-sm">${formatCurrency(ev.totalCost)}</span>
              </div>
              <div class="text-right">
                <span class="text-slate-400 block text-[10px]">Balance Due</span>
                <span class="font-bold font-mono text-sm ${ev.balanceDue > 0 ? 'text-rose-600' : 'text-emerald-600'}">
                  ${ev.balanceDue > 0 ? formatCurrency(ev.balanceDue) : 'Paid in Full'}
                </span>
              </div>
            </div>
          </div>
        `).join('')}
      </div>
    </div>
  `;
}

// -------------------------------------------------------------
// 5. CUSTOMER DIRECTORY VIEW
// -------------------------------------------------------------
function renderCustomersView() {
  let list = store.data.customers;
  if (store.customerSearch) {
    const q = store.customerSearch.toLowerCase();
    list = list.filter(c => c.name.toLowerCase().includes(q) || c.phone.includes(q) || (c.email && c.email.toLowerCase().includes(q)));
  }

  return `
    <div class="space-y-4 max-w-7xl mx-auto">
      <div class="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex flex-col sm:flex-row gap-3 items-center justify-between">
        <div class="relative w-full sm:w-80">
          <i class="fa-solid fa-search absolute left-3.5 top-3 text-slate-400 text-xs"></i>
          <input type="text" placeholder="Search customers by name, phone..." value="${store.customerSearch || ''}" oninput="store.customerSearch = this.value; renderSectionContent('customers')" class="w-full pl-9 pr-3 py-2 text-xs border border-slate-200 rounded-xl focus:ring-2 focus:ring-brand outline-none">
        </div>
        <button onclick="openModal('addCustomerModal')" class="w-full sm:w-auto py-2 px-4 bg-brand text-white font-bold text-xs rounded-xl shadow-sm flex items-center justify-center gap-2">
          <i class="fa-solid fa-user-plus"></i> Add Customer
        </button>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        ${list.length === 0 ? `
          <div class="col-span-full py-12 text-center bg-white rounded-2xl border border-slate-200 shadow-sm">
            <i class="fa-solid fa-users text-4xl text-slate-300 mb-3 block"></i>
            <h4 class="text-sm font-bold text-slate-700">No customer records</h4>
            <p class="text-xs text-slate-400 mt-1">Customers will automatically appear here as enquiries and bookings are created, or you can add one manually.</p>
          </div>
        ` : list.map(c => `
          <div class="bg-white rounded-2xl border border-slate-200 p-5 shadow-sm hover:border-blue-300 transition flex flex-col justify-between">
            <div>
              <div class="flex items-center gap-3 mb-3">
                <div class="w-10 h-10 rounded-full bg-blue-100 text-brand flex items-center justify-center font-bold text-sm">
                  ${(c.name || 'C').substring(0, 2).toUpperCase()}
                </div>
                <div>
                  <h4 class="font-bold text-sm text-slate-900">${c.name}</h4>
                  <a href="tel:${c.phone}" class="text-xs text-brand font-semibold hover:underline">${c.phone}</a>
                </div>
              </div>

              <div class="space-y-1 text-xs text-slate-500 bg-slate-50 p-3 rounded-xl mb-3">
                ${c.email ? `<div><i class="fa-solid fa-envelope mr-1.5 text-slate-400"></i> ${c.email}</div>` : ''}
                ${c.address ? `<div><i class="fa-solid fa-location-dot mr-1.5 text-slate-400"></i> ${c.address}</div>` : '<div class="text-slate-400 italic">No address on file</div>'}
              </div>
            </div>

            <div class="flex justify-end gap-2 pt-2 border-t border-slate-100">
              <a href="tel:${c.phone}" class="py-1 px-3 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-lg text-xs font-semibold flex items-center gap-1.5"><i class="fa-solid fa-phone text-[10px]"></i> Call</a>
            </div>
          </div>
        `).join('')}
      </div>
    </div>
  `;
}

// -------------------------------------------------------------
// 7. FINANCE & REPORTS VIEW
// -------------------------------------------------------------
function renderFinanceView() {
  const totalIncome = store.data.payments.reduce((acc, p) => acc + Number(p.amount), 0);
  const totalExpenses = store.data.expenses.reduce((acc, e) => acc + Number(e.amount), 0);
  const totalEnquiries = store.data.enquiries.length;
  const convertedCount = store.data.enquiries.filter(e => e.convertedEventId || e.status === 'Confirmed').length;
  const conversionRate = totalEnquiries > 0 ? ((convertedCount / totalEnquiries) * 100).toFixed(1) : 0;

  return `
    <div class="space-y-6 max-w-7xl mx-auto">
      <!-- Conversion Rate Feature Card -->
      <div class="bg-white rounded-2xl border border-slate-200 p-5 shadow-sm">
        <div class="flex items-center justify-between mb-3">
          <div>
            <h3 class="font-bold text-sm text-slate-900">Enquiry-to-Booking Conversion Rate</h3>
            <p class="text-xs text-slate-500">Sales pipeline tracking from initial enquiry to confirmed reservation</p>
          </div>
          <span class="text-xl font-bold text-brand font-mono">${conversionRate}%</span>
        </div>

        <div class="w-full bg-slate-100 rounded-full h-3 mb-4 overflow-hidden">
          <div class="bg-brand h-3 rounded-full transition-all duration-500" style="width: ${conversionRate}%"></div>
        </div>

        <div class="grid grid-cols-3 gap-2 text-center text-xs">
          <div class="p-2 bg-slate-50 rounded-xl">
            <span class="text-slate-400 block text-[11px]">Total Leads</span>
            <strong class="text-base text-slate-800">${totalEnquiries}</strong>
          </div>
          <div class="p-2 bg-emerald-50 rounded-xl">
            <span class="text-emerald-600 block text-[11px]">Converted Bookings</span>
            <strong class="text-base text-emerald-700">${convertedCount}</strong>
          </div>
          <div class="p-2 bg-blue-50 rounded-xl">
            <span class="text-blue-600 block text-[11px]">Active Opportunities</span>
            <strong class="text-base text-brand">${totalEnquiries - convertedCount}</strong>
          </div>
        </div>
      </div>

      <!-- Payment Collections Ledger -->
      <div class="bg-white rounded-2xl border border-slate-200 p-5 shadow-sm">
        <div class="flex items-center justify-between mb-4">
          <h3 class="font-bold text-sm text-slate-900">Payment Transactions</h3>
          <span class="text-xs font-mono font-bold text-emerald-600">Total: ${formatCurrency(totalIncome)}</span>
        </div>

        <div class="space-y-2">
          ${store.data.payments.length === 0 ? `
            <div class="p-8 text-center text-slate-400 text-xs">No payments recorded yet. Record advances or payments against confirmed events.</div>
          ` : store.data.payments.map(p => {
    const ev = store.data.events.find(e => e.id === p.eventId);
    return `
              <div class="p-3 bg-slate-50 rounded-xl flex items-center justify-between text-xs">
                <div>
                  <div class="font-bold text-slate-800">${ev ? ev.customerName : 'Client'} (${ev ? ev.eventNumber : ''})</div>
                  <div class="text-[11px] text-slate-500">${p.paymentType} via ${p.paymentMethod} • ${formatDate(p.date)} ${p.ref ? `• ${p.ref}` : ''}</div>
                </div>
                <div class="font-bold text-emerald-600 font-mono text-sm">${formatCurrency(p.amount)}</div>
              </div>
            `;
  }).join('')}
        </div>
      </div>

      <!-- Operational Expenses -->
      <div class="bg-white rounded-2xl border border-slate-200 p-5 shadow-sm">
        <div class="flex items-center justify-between mb-4">
          <div class="flex items-center gap-3">
            <h3 class="font-bold text-sm text-slate-900">Venue Expenses</h3>
            <span class="text-xs font-mono font-bold text-rose-600">Total: ${formatCurrency(totalExpenses)}</span>
          </div>
          <button onclick="openModal('addExpenseModal')" class="py-1.5 px-3 bg-rose-600 hover:bg-rose-700 text-white font-bold text-xs rounded-xl shadow-xs flex items-center gap-1.5 transition">
            <i class="fa-solid fa-plus text-[10px]"></i> Add Expense
          </button>
        </div>

        <div class="space-y-2">
          ${store.data.expenses.length === 0 ? `
            <div class="p-8 text-center text-slate-400 text-xs">No expenses recorded yet. Click "+ Add Expense" to track venue operating costs.</div>
          ` : store.data.expenses.map(ex => `
            <div class="p-3 bg-slate-50 rounded-xl flex items-center justify-between text-xs">
              <div>
                <div class="font-bold text-slate-800">${ex.title}</div>
                <div class="text-[11px] text-slate-500">${ex.category} • ${formatDate(ex.date)}</div>
              </div>
              <div class="font-bold text-rose-600 font-mono text-sm">${formatCurrency(ex.amount)}</div>
            </div>
          `).join('')}
        </div>
      </div>
    </div>
  `;
}

// -------------------------------------------------------------
// MODALS AND INTERACTION HANDLERS
// -------------------------------------------------------------
function openModal(modalId) {
  document.getElementById('modalBackdrop').classList.remove('hidden');
  document.querySelectorAll('#modalBackdrop > div').forEach(el => el.classList.add('hidden'));
  document.getElementById(modalId).classList.remove('hidden');
  store.activeModal = modalId;
}

function closeModal() {
  document.getElementById('modalBackdrop').classList.add('hidden');
  document.querySelectorAll('#modalBackdrop > div').forEach(el => el.classList.add('hidden'));
  store.activeModal = null;
}

// Enquiry Detail Popup
function openEnquiryDetail(enquiryId) {
  const enq = store.data.enquiries.find(e => e.id === enquiryId);
  if (!enq) return;
  store.currentDetailItem = enq;

  document.getElementById('edName').innerText = enq.customerName;
  document.getElementById('edNumber').innerText = enq.enquiryNumber;
  document.getElementById('edPhone').innerText = enq.phone;
  document.getElementById('edEventType').innerText = enq.eventType;
  document.getElementById('edGuests').innerText = `${enq.guests} Guests`;
  document.getElementById('edDate').innerText = formatDate(enq.preferredDate);
  document.getElementById('edTime').innerText = enq.preferredTime;
  document.getElementById('edBudget').innerText = formatCurrency(enq.expectedBudget);
  const statusSelect = document.getElementById('edStatusSelect');
  if (statusSelect) {
    statusSelect.value = enq.status || 'New';
  }
  document.getElementById('edNotes').innerText = enq.notes || 'No special requirements noted.';
  document.getElementById('edCallBtn').href = `tel:${enq.phone}`;

  const statusBadge = document.getElementById('edStatusBadge');
  statusBadge.innerText = enq.status;
  statusBadge.className = `text-xs px-2.5 py-0.5 rounded-full font-bold ${getStatusBadgeClass(enq.status)}`;

  const convBtn = document.getElementById('edConvertBtn');
  if (enq.convertedEventId || enq.status === 'Confirmed') {
    convBtn.innerHTML = '<i class="fa-solid fa-check"></i> Already Converted';
    convBtn.disabled = true;
    convBtn.classList.replace('bg-emerald-600', 'bg-slate-400');
  } else {
    convBtn.innerHTML = '<i class="fa-solid fa-circle-check"></i> Convert to Event';
    convBtn.disabled = false;
    convBtn.classList.replace('bg-slate-400', 'bg-emerald-600');
  }

  // Follow-up history timeline
  const followUps = store.data.followUps.filter(f => f.enquiryId === enquiryId);
  document.getElementById('edTimeline').innerHTML = followUps.length === 0 ? '<p class="text-xs text-slate-400 py-1">No notes recorded yet.</p>' : followUps.map(f => `
    <div class="p-2.5 bg-slate-50 border border-slate-200 rounded-lg text-xs">
      <div class="flex justify-between items-center text-[10px] text-slate-400 mb-1">
        <span class="font-bold text-amber-700">${f.newStatus || 'Note'}</span>
        <span>${formatDate(f.date)}</span>
      </div>
      <p class="text-slate-700">${f.note}</p>
    </div>
  `).join('');

  openModal('enquiryDetailModal');
}

function updateCurrentEnquiryStatus(newStatus) {
  if (!store.currentDetailItem) return;
  const enq = store.currentDetailItem;
  const oldStatus = enq.status;
  enq.status = newStatus;
  const statusBadge = document.getElementById('edStatusBadge');
  if (statusBadge) {
    statusBadge.innerText = newStatus;
    statusBadge.className = `text-xs px-2.5 py-0.5 rounded-full font-bold ${getStatusBadgeClass(newStatus)}`;
  }
  store.data.followUps.unshift({
    id: Date.now(),
    enquiryId: enq.id,
    note: `Status updated from ${oldStatus} to ${newStatus}`,
    newStatus: newStatus,
    date: new Date().toISOString().split('T')[0]
  });
  store.save();
  renderSidebar();
  renderMobileNav();
  if (store.currentTab === 'enquiries') {
    renderSectionContent('enquiries');
  }
}

// Event Detail Popup (Google Calendar style)
function openEventDetail(eventId) {
  const ev = store.data.events.find(e => e.id === eventId);
  if (!ev) return;
  store.currentDetailItem = ev;

  document.getElementById('evCustomer').innerText = ev.customerName;
  document.getElementById('evNumber').innerText = ev.eventNumber;
  document.getElementById('evType').innerText = ev.eventType;
  document.getElementById('evGuests').innerText = `${ev.guests} Guests`;
  document.getElementById('evDate').innerText = formatDate(ev.eventDate);
  document.getElementById('evTime').innerText = `${ev.startTime} – ${ev.endTime}`;
  document.getElementById('evPhone').innerText = ev.phone;
  document.getElementById('evCost').innerText = formatCurrency(ev.totalCost);
  document.getElementById('evAdvance').innerText = formatCurrency(ev.advancePaid);
  document.getElementById('evBalance').innerText = formatCurrency(ev.balanceDue);
  document.getElementById('evNotes').innerText = ev.notes || 'None';
  document.getElementById('evCallLink').href = `tel:${ev.phone}`;

  const statusBadge = document.getElementById('evStatusBadge');
  statusBadge.innerText = ev.status;
  statusBadge.className = `text-xs px-2.5 py-0.5 rounded-full font-bold ${getStatusBadgeClass(ev.status)}`;

  // Payments for this event
  const payments = store.data.payments.filter(p => p.eventId === ev.id);
  document.getElementById('evPaymentsList').innerHTML = payments.length === 0 ? '<p class="text-xs text-slate-400">No payments recorded.</p>' : payments.map(p => `
    <div class="flex justify-between p-2 bg-slate-50 rounded-lg border border-slate-100">
      <span>${p.paymentType} (${p.paymentMethod}) - ${formatDate(p.date)}</span>
      <span class="font-bold text-emerald-600 font-mono">${formatCurrency(p.amount)}</span>
    </div>
  `).join('');

  openModal('eventDetailModal');
}

// Convert Enquiry Flow
function openConvertModal(enquiryId) {
  const enq = store.data.enquiries.find(e => e.id === enquiryId);
  if (!enq) return;

  document.getElementById('convEnquiryId').value = enq.id;
  document.getElementById('convSummary').innerText = `Converting lead: ${enq.customerName} (${enq.eventType} • ${enq.guests} guests)`;
  document.getElementById('convDate').value = enq.preferredDate;
  document.getElementById('convTime').value = enq.preferredTime;
  document.getElementById('convTotalCost').value = enq.expectedBudget || 50000;
  document.getElementById('convAdvance').value = Math.min(10000, enq.expectedBudget || 10000);

  openModal('convertModal');
}

function initiateEnquiryConversion() {
  if (store.currentDetailItem) {
    openConvertModal(store.currentDetailItem.id);
  }
}

function handleConvertSubmit(e) {
  e.preventDefault();
  const enqId = Number(document.getElementById('convEnquiryId').value);
  const enq = store.data.enquiries.find(item => item.id === enqId);
  if (!enq) return;

  const totalCost = Number(document.getElementById('convTotalCost').value);
  const advance = Number(document.getElementById('convAdvance').value);
  const balance = Math.max(0, totalCost - advance);

  const nextEvtNum = 'EVT-' + String(store.data.events.length + 1).padStart(3, '0');

  // 1. Create Confirmed Event
  const newEvent = {
    id: Date.now(),
    eventNumber: nextEvtNum,
    enquiryId: enq.id,
    customerName: enq.customerName,
    phone: enq.phone,
    email: enq.email,
    eventType: enq.eventType,
    guests: enq.guests,
    eventDate: document.getElementById('convDate').value,
    startTime: '10:00 AM',
    endTime: '05:00 PM',
    totalCost: totalCost,
    advancePaid: advance,
    balanceDue: balance,
    notes: enq.notes,
    status: 'Confirmed',
    createdAt: new Date().toISOString()
  };

  store.data.events.push(newEvent);

  // 2. Add advance payment if paid
  if (advance > 0) {
    store.data.payments.push({
      id: Date.now() + 1,
      eventId: newEvent.id,
      amount: advance,
      paymentType: 'Advance',
      paymentMethod: document.getElementById('convPaymentMethod').value,
      date: new Date().toISOString().split('T')[0],
      ref: 'Advance on booking confirmation'
    });
  }

  // 3. Update enquiry record
  enq.status = 'Confirmed';
  enq.convertedEventId = newEvent.id;

  // 4. Log conversion note
  store.data.followUps.push({
    id: Date.now() + 2,
    enquiryId: enq.id,
    note: `Enquiry converted into Confirmed Booking ${nextEvtNum}. Advance: ${formatCurrency(advance)}`,
    newStatus: 'Confirmed',
    date: new Date().toISOString().split('T')[0]
  });

  // Ensure customer record is synchronized
  ensureCustomer(enq.customerName, enq.phone, enq.email);

  store.save();
  closeModal();
  switchTab('calendar');
  alert(`Success! Lead converted to ${nextEvtNum}. It is now live in the Google Calendar schedule!`);
}

// Create New Enquiry
function handleNewEnquirySubmit(e) {
  e.preventDefault();
  const nextEnqNum = 'ENQ-' + String(store.data.enquiries.length + 1).padStart(3, '0');

  const newEnq = {
    id: Date.now(),
    enquiryNumber: nextEnqNum,
    customerName: document.getElementById('neName').value.trim(),
    phone: document.getElementById('nePhone').value.trim(),
    eventType: document.getElementById('neType').value.trim(),
    guests: Number(document.getElementById('neGuests').value),
    expectedBudget: Number(document.getElementById('neBudget').value) || 0,
    preferredDate: document.getElementById('neDate').value,
    preferredTime: document.getElementById('neTime').value,
    status: document.getElementById('neStatus') ? document.getElementById('neStatus').value : 'New',
    notes: document.getElementById('neNotes').value.trim(),
    convertedEventId: null,
    createdAt: new Date().toISOString()
  };

  store.data.enquiries.unshift(newEnq);
  ensureCustomer(newEnq.customerName, newEnq.phone);
  store.save();
  closeModal();
  switchTab('enquiries');
}

function handleNewEventSubmit(e) {
  e.preventDefault();
  const total = Number(document.getElementById('evCustTotalCost').value);
  const adv = Number(document.getElementById('evCustAdvance').value) || 0;
  const nextEvtNum = 'EVT-' + String(store.data.events.length + 1).padStart(3, '0');

  const newEvent = {
    id: Date.now(),
    eventNumber: nextEvtNum,
    customerName: document.getElementById('evCustName').value.trim(),
    phone: document.getElementById('evCustPhone').value.trim(),
    eventType: document.getElementById('evCustType').value.trim(),
    guests: Number(document.getElementById('evCustGuests').value),
    eventDate: document.getElementById('evCustDate').value,
    startTime: '10:00 AM',
    endTime: '05:00 PM',
    totalCost: total,
    advancePaid: adv,
    balanceDue: Math.max(0, total - adv),
    notes: document.getElementById('evCustNotes').value.trim(),
    status: 'Confirmed',
    createdAt: new Date().toISOString()
  };

  store.data.events.unshift(newEvent);

  if (adv > 0) {
    store.data.payments.push({
      id: Date.now() + 1,
      eventId: newEvent.id,
      amount: adv,
      paymentType: 'Advance',
      paymentMethod: 'Cash',
      date: new Date().toISOString().split('T')[0],
      ref: 'Advance on booking'
    });
  }

  ensureCustomer(newEvent.customerName, newEvent.phone);

  store.save();
  closeModal();
  switchTab('calendar');
}

// Payment Recording
function openPaymentForCurrentEvent() {
  if (!store.currentDetailItem) return;
  const ev = store.currentDetailItem;
  document.getElementById('payEventId').value = ev.id;
  document.getElementById('payEventSummary').innerText = `${ev.eventNumber} - ${ev.customerName} (Bal due: ${formatCurrency(ev.balanceDue)})`;
  document.getElementById('payAmount').value = ev.balanceDue > 0 ? ev.balanceDue : 5000;
  openModal('paymentModal');
}

function handleRecordPaymentSubmit(e) {
  e.preventDefault();
  const eventId = Number(document.getElementById('payEventId').value);
  const amount = Number(document.getElementById('payAmount').value);
  const ev = store.data.events.find(item => item.id === eventId);
  if (!ev) return;

  store.data.payments.push({
    id: Date.now(),
    eventId: eventId,
    amount: amount,
    paymentType: document.getElementById('payType').value,
    paymentMethod: document.getElementById('payMethod').value,
    date: new Date().toISOString().split('T')[0],
    ref: document.getElementById('payRef').value.trim() || 'Direct payment'
  });

  ev.advancePaid += amount;
  ev.balanceDue = Math.max(0, ev.totalCost - ev.advancePaid);

  store.save();
  closeModal();
  openEventDetail(eventId);
}

function promptAddFollowUp() {
  if (!store.currentDetailItem) return;
  const enq = store.currentDetailItem;
  const note = prompt("Enter conversation notes with customer:");
  if (note && note.trim()) {
    store.data.followUps.unshift({
      id: Date.now(),
      enquiryId: enq.id,
      note: note.trim(),
      newStatus: enq.status,
      date: new Date().toISOString().split('T')[0]
    });
    store.save();
    openEnquiryDetail(enq.id);
  }
}

function cancelCurrentEvent() {
  if (!store.currentDetailItem) return;
  if (confirm(`Are you sure you want to cancel booking ${store.currentDetailItem.eventNumber}? This releases the reservation.`)) {
    store.currentDetailItem.status = 'Cancelled';
    store.save();
    closeModal();
    switchTab('events');
  }
}

function ensureCustomer(name, phone, email = '', address = '') {
  if (!name || !phone) return;
  let existing = store.data.customers.find(c => c.phone === phone || c.name.toLowerCase() === name.toLowerCase());
  if (!existing) {
    store.data.customers.push({
      id: Date.now() + Math.floor(Math.random() * 1000),
      name: name,
      phone: phone,
      email: email,
      address: address
    });
  } else {
    if (email && !existing.email) existing.email = email;
    if (address && !existing.address) existing.address = address;
  }
}

function handleAddCustomerSubmit(e) {
  e.preventDefault();
  const name = document.getElementById('custName').value.trim();
  const phone = document.getElementById('custPhone').value.trim();
  const email = document.getElementById('custEmail').value.trim();
  const address = document.getElementById('custAddress').value.trim();

  ensureCustomer(name, phone, email, address);
  store.save();
  closeModal();
  e.target.reset();
  if (store.currentTab === 'customers') {
    renderSectionContent('customers');
  } else {
    switchTab('customers');
  }
}

function handleAddExpenseSubmit(e) {
  e.preventDefault();
  const title = document.getElementById('expTitle').value.trim();
  const amount = Number(document.getElementById('expAmount').value);
  const category = document.getElementById('expCategory').value;
  const date = document.getElementById('expDate').value;

  store.data.expenses.unshift({
    id: Date.now(),
    title: title,
    amount: amount,
    category: category,
    date: date
  });

  store.save();
  closeModal();
  e.target.reset();
  if (store.currentTab === 'finance') {
    renderSectionContent('finance');
  } else if (store.currentTab === 'dashboard') {
    renderSectionContent('dashboard');
  }
}

function toggleMobileMenu() {
  alert("Navigate using the bottom navigation bar or top buttons!");
}

