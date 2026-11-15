# Event & Venue Management System

A production-grade, offline-first **Event & Venue Management System** built with **Flutter**, **SQLite**, and modern Material Design 3. The system features an interactive Google Calendar-style schedule, a dedicated sales enquiry CRM pipeline with one-tap conversion to confirmed events, hall slot conflict prevention, customer directory, and financial reporting.

---

## 🌟 Key Features

### 1. Dedicated Enquiry CRM Pipeline
- **Separate Enquiries Module**: Dedicated navigation screen with search (by customer name, mobile number, enquiry #) and status filters (`New`, `Contacted`, `Follow-up`, `Quotation Sent`, `Confirmed`, `Lost`, `Cancelled`).
- **Detailed Customer Enquiry Sheet**: Displays customer contact, event requirements, expected budget, hall availability status, and complete follow-up activity history.
- **One-Tap Customer Calling**: Direct phone dialer action via `url_launcher`.
- **Follow-up Reminders**: Follow-up dates with instant reminder badges on the Dashboard and Calendar.
- **Enquiry-to-Booking Conversion**:
  - Validates hall availability for the target date and time slot.
  - Automatically transfers customer details and event parameters.
  - Records initial advance payment and payment method.
  - Updates enquiry status to `Confirmed` and links to the generated `Event ID`.
  - Preserves full enquiry audit trail and prevents duplicate conversions.

### 2. Google Calendar-Style Interactive Schedule
- **Multiple Views**: Month view, Week view, Day view, and chronological Agenda list.
- **Navigation Controls**: Previous/Next period buttons, "Today" quick-jump, and full date picker.
- **Hall Filtering**: Filter events by specific hall (e.g. Hall A Grand Ballroom, Hall B Pearl Banquet) or view all halls.
- **Color-Coded Event Chips**: Visual distinction by status and event type.
- **Interactive Slots**:
  - Click any date to view all scheduled events and enquiry follow-ups.
  - Click an event card to open the **Event Detail Popup**.
  - Tap any date / empty slot to schedule a new booking.
- **Follow-up Separation**: Follow-up reminders are shown with distinct amber indicators so leads are never lost.

### 3. Event Detail Popup
- Displays: Event ID, customer name, mobile number, event type, guest count, event date, start/end timings, hall name, total cost, advance paid, remaining balance due, and booking notes.
- Quick actions: **Call Customer**, **Edit Event**, **Payment History**, **Record Further Payment**, and **Cancel Booking**.

### 4. Hall Management & Double-Booking Prevention
- Manage multiple halls with capacity, base rates, amenities, and active status.
- Real-time slot availability check considering date, start time, and end time.
- Allows multiple events in different halls on the same date while preventing overlapping bookings in the same hall.
- Supports **Temporary Hall Holds** with automatic expiration dates.

### 5. Finance & Performance Reports
- Income tracking (advance, part payments, final balance, security deposits).
- Operational expense logger categorized by Maintenance, Staff, Utilities, Catering, etc.
- Balance due collection tracker.
- **Conversion Analytics**: Visual enquiry-to-booking conversion rate progress bar.
- Export and share financial summaries via text/messaging apps.

### 6. Offline-First SQLite Architecture
- Uses local SQLite database (`sqflite` on Android/iOS and `sqflite_common_ffi` on desktop).
- No internet connection required for day-to-day operations.
- Full backup & restore feature: Export all database tables into JSON.

---

## 🗄️ SQLite Database Schema

| Table | Purpose |
|---|---|
| `customers` | Customer contact directory, address, and notes |
| `halls` | Hall names, capacities, base rates, and amenities |
| `enquiries` | Customer leads, budget, status, preferred hall/timing, and converted event link |
| `follow_ups` | Log of conversation notes, status changes, and next follow-up dates |
| `hall_holds` | Temporary reservation holds with expiration timestamps |
| `events` | Confirmed bookings, date/time slots, costs, advance paid, balance due |
| `payments` | Transaction ledger (Cash, UPI, Bank Transfer, Card, Cheque) |
| `expenses` | Venue operational expenses and overheads |

---

## 🚀 Getting Started & Building Android APK

### Step 1: Install Flutter SDK (if not already installed)
You can run the automated setup script included in this repository:
```powershell
.\setup_flutter.ps1
```
Or manually download Flutter from [flutter.dev](https://docs.flutter.dev/get-started/install/windows/mobile) and add `C:\src\flutter\bin` to your `PATH`.

### Step 2: Install Project Dependencies
```bash
cd d:\management-app
flutter pub get
```

### Step 3: Run the App
- **On Connected Android Phone / Emulator**:
  ```bash
  flutter run
  ```
- **On Windows Desktop**:
  ```bash
  flutter run -d windows
  ```

### Step 4: Build the Release Android APK
To compile the standalone release APK for installation on mobile devices:
```bash
flutter build apk --release
```
The compiled APK will be generated at:
`build/app/outputs/flutter-apk/app-release.apk`

Transfer this `.apk` file to any Android device to install and use the app completely offline!

