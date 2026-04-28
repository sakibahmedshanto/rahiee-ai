# 📂 Rahiee.AI - Project Structure & Code Organization

> **Complete guide to understanding the codebase structure**

---

## 📖 Table of Contents

1. [Project Overview](#project-overview)
2. [Directory Structure](#directory-structure)
3. [Core Services](#core-services)
4. [Controllers](#controllers)
5. [Database Structure](#database-structure)
6. [Key Features](#key-features)
7. [Code Flow](#code-flow)

---

## 🎯 Project Overview

**Rahiee.AI** is a Flutter-based employee schedule and attendance management system with:

- ✅ Multi-user schedule assignments
- ✅ Real-time attendance tracking with geolocation
- ✅ Schedule exchange system for employees
- ✅ Admin dashboard for management
- ✅ Supabase backend (PostgreSQL)
- ✅ GetX state management

---

## 📁 Directory Structure

```
rahiee_ai/
├── lib/
│   ├── controllers/          # GetX controllers for state management
│   │   ├── admin_controllers/
│   │   │   └── admin_schedule_controller.dart
│   │   ├── auth_controller/
│   │   │   ├── google_sign_in_controller.dart
│   │   │   ├── sign_in_controller.dart
│   │   │   └── sign_up_controller.dart
│   │   ├── schedule_exchange_controller.dart
│   │   └── unified_schedule_controller.dart
│   │
│   ├── models/              # Data models
│   │   ├── schedule_model.dart
│   │   ├── user_model.dart
│   │   └── attendance_model.dart
│   │
│   ├── screens/             # UI screens
│   │   ├── admin/
│   │   │   ├── admin_screen/
│   │   │   │   ├── tabs/
│   │   │   │   │   ├── components/
│   │   │   │   │   │   ├── schedule_create_tab.dart
│   │   │   │   │   │   └── schedule_table_tab.dart
│   │   │   │   │   └── admin_schedules_tab.dart
│   │   │   └── exchange_request_screen.dart
│   │   │
│   │   └── schedule_screen/
│   │       ├── unified_schedule_screen.dart
│   │       └── create_exchange_request_screen.dart
│   │
│   ├── services/            # Business logic & API calls
│   │   ├── admin_schedule_service.dart
│   │   ├── attendance_management_service.dart
│   │   ├── location_permission_service.dart
│   │   ├── multi_user_schedule_service.dart
│   │   ├── schedule_exchange_service.dart
│   │   ├── schedule_service.dart
│   │   └── supabase_service.dart
│   │
│   ├── utils/               # Utilities and constants
│   │   ├── app_constant.dart
│   │   └── helpers.dart
│   │
│   └── main.dart            # App entry point
│
├── sql/                     # Database migration scripts
│   ├── multi_user_schedule_system.sql
│   ├── schedule_exchange_functions.sql
│   ├── update_schedule_exchange_for_multi_user.sql
│   ├── attendance_functions.sql
│   ├── comprehensive_attendance_system.sql
│   ├── cleanup_unused_rpcs.sql
│   ├── test_multi_user_schedule_system.sql
│   └── README.md
│
├── docs/                    # Documentation
│   ├── DATABASE_COMPLETE_REFERENCE.md
│   ├── RPC_QUICK_REFERENCE.md
│   └── database_schema.md
│
└── PROJECT_STRUCTURE.md     # This file
```

---

## 🔧 Core Services

### 1. `supabase_service.dart`
**Purpose**: Supabase client initialization and configuration

**Responsibilities**:
- Initialize Supabase client
- Provide global access to Supabase instance
- Handle authentication state

**Usage**:
```dart
final supabase = SupabaseService.client;
```

---

### 2. `schedule_service.dart`
**Purpose**: Schedule data fetching and management

**Key Methods**:
- `getSchedulesForUser(userId, date)` - Fetch user schedules
- Uses `get_schedules_with_attendance_status` RPC

**Usage**:
```dart
final schedules = await ScheduleService.getSchedulesForUser(userId, date);
```

---

### 3. `multi_user_schedule_service.dart`
**Purpose**: Multi-user schedule assignment operations

**Key Methods**:
- `assignUsersToSchedule()` - Assign multiple users
- `removeUserFromSchedule()` - Remove user from schedule
- `getScheduleWithAssignments()` - Get schedule with all users
- `getAvailableUsersForSchedule()` - Find available users

**Usage**:
```dart
await MultiUserScheduleService.assignUsersToSchedule(
  scheduleId: scheduleId,
  userIds: selectedUserIds,
  adminId: adminId,
);
```

---

### 4. `schedule_exchange_service.dart`
**Purpose**: Schedule exchange/swap system

**Key Methods**:
- `createExchangeRequest()` - Employee creates exchange request
- `manageExchangeRequest()` - Admin approves/rejects request
- `getExchangeRequests()` - List exchange requests
- `cancelExchangeRequest()` - User cancels own request
- `getAvailableUsersForExchange()` - Find available users

**Usage**:
```dart
final result = await ScheduleExchangeService.createExchangeRequest(
  requesterUserId: userId,
  scheduleId: scheduleId,
  requestedUserId: targetUserId,
  requestReason: reason,
);
```

---

### 5. `attendance_management_service.dart`
**Purpose**: Attendance check-in/check-out operations

**Key Methods**:
- `checkIn()` - Employee check-in
- `checkOut()` - Employee check-out
- `getAttendanceForSchedule()` - Get attendance record

**Usage**:
```dart
await AttendanceManagementService.checkIn(
  userId: userId,
  scheduleId: scheduleId,
  latitude: lat,
  longitude: lng,
);
```

---

### 6. `admin_schedule_service.dart`
**Purpose**: Admin schedule creation and management

**Key Methods**:
- `createSchedule()` - Create new schedule
- `updateSchedule()` - Update existing schedule
- `deleteSchedule()` - Delete schedule
- `getSchedules()` - List all schedules

**Usage**:
```dart
await AdminScheduleService.createSchedule(
  title: title,
  description: description,
  startDateTime: start,
  endDateTime: end,
  ...
);
```

---

### 7. `location_permission_service.dart`
**Purpose**: Handle location permissions and GPS

**Key Methods**:
- `requestLocationPermission()` - Request permission
- `getCurrentLocation()` - Get current GPS coordinates
- `isLocationEnabled()` - Check if GPS is on

**Usage**:
```dart
final position = await LocationPermissionService.getCurrentLocation();
```

---

## 🎮 Controllers

### 1. `UnifiedScheduleController`
**Purpose**: Employee schedule view and management

**Responsibilities**:
- Load user schedules for selected date
- Handle date navigation
- Manage attendance check-in/check-out
- Display schedule details

**Observable Variables**:
- `schedules` - List of schedules
- `selectedDate` - Currently selected date
- `isLoading` - Loading state

---

### 2. `ScheduleExchangeController`
**Purpose**: Schedule exchange request management

**Responsibilities**:
- Create exchange requests
- List pending/approved/rejected requests
- Load available users for exchange
- Filter requests by status

**Observable Variables**:
- `exchangeRequests` - All exchange requests
- `availableUsers` - Users available for exchange
- `isLoading` - Loading state
- `isCreatingRequest` - Creation in progress

**Key Methods**:
- `createExchangeRequest()` - Submit request
- `manageExchangeRequest()` - Admin approve/reject
- `loadAvailableUsersForExchange()` - Find available users

---

### 3. `AdminScheduleController`
**Purpose**: Admin schedule creation and multi-user assignment

**Responsibilities**:
- Create schedules
- Toggle multi-user mode
- Select multiple users for assignment
- Manage participant limits
- Assign/remove users from schedules

**Observable Variables**:
- `schedules` - All schedules
- `isMultiUserMode` - Multi-user toggle
- `selectedUsers` - Selected users for assignment
- `isLoading` - Loading state

**Key Methods**:
- `createSchedule()` - Create schedule (returns schedule_id)
- `assignMultipleUsersToSchedule()` - Assign multiple users
- `toggleMultiUserMode()` - Switch single/multi mode
- `toggleUserSelection()` - Select/deselect users

---

### 4. Auth Controllers
**Purpose**: Handle authentication

- `SignInController` - Email/password sign-in
- `SignUpController` - User registration
- `GoogleSignInController` - Google OAuth sign-in

---

## 🗄️ Database Structure

### Core Tables

1. **`my_users`** - User accounts (employees, admins)
2. **`employee_schedules`** - Schedule definitions
3. **`schedule_assignments`** - Multi-user assignments (junction table)
4. **`attendance`** - Check-in/check-out records
5. **`schedule_exchange_requests`** - Exchange requests

### Key Relationships

```
my_users
    ↓
employee_schedules
    ↓
schedule_assignments ← (many-to-many with my_users)
    ↓
attendance
```

**For complete database documentation, see:**
- [docs/DATABASE_COMPLETE_REFERENCE.md](docs/DATABASE_COMPLETE_REFERENCE.md)
- [docs/RPC_QUICK_REFERENCE.md](docs/RPC_QUICK_REFERENCE.md)

---

## 🎯 Key Features

### 1. Multi-User Schedule Assignment

**Flow**:
```
Admin → Toggle multi-user mode
     → Select multiple users
     → Set min/max participants
     → Create schedule
     → System calls assign_users_to_schedule RPC
     → Each user sees schedule in their list
```

**Files Involved**:
- `lib/screens/admin/admin_screen/tabs/components/schedule_create_tab.dart`
- `lib/controllers/admin_controllers/admin_schedule_controller.dart`
- `lib/services/multi_user_schedule_service.dart`

---

### 2. Schedule Exchange System

**Flow**:
```
Employee → Views schedule
        → Clicks "Change Schedule"
        → Selects available user
        → Submits exchange request
        → Admin reviews in exchange_request_screen
        → Admin approves/rejects
        → On approve: System updates schedule_assignments
```

**Files Involved**:
- `lib/screens/schedule_screen/unified_schedule_screen.dart` (Employee view)
- `lib/screens/schedule_screen/create_exchange_request_screen.dart` (Request form)
- `lib/screens/admin/exchange_request_screen.dart` (Admin review)
- `lib/controllers/schedule_exchange_controller.dart`
- `lib/services/schedule_exchange_service.dart`

---

### 3. Attendance Tracking

**Flow**:
```
Employee → Views today's schedules
        → Clicks "Check In" (with GPS)
        → System creates attendance record
        → Later clicks "Check Out" (with GPS)
        → System calculates work duration
```

**Files Involved**:
- `lib/screens/schedule_screen/unified_schedule_screen.dart`
- `lib/controllers/unified_schedule_controller.dart`
- `lib/services/attendance_management_service.dart`
- `lib/services/location_permission_service.dart`

---

## 🔄 Code Flow Examples

### Loading User Schedules

```
UnifiedScheduleScreen (UI)
    ↓
UnifiedScheduleController.loadSchedulesForDate()
    ↓
ScheduleService.getSchedulesForUser()
    ↓
Supabase RPC: get_schedules_with_attendance_status
    ↓
Database Query (joins schedules + attendance)
    ↓
Returns JSON with schedules array
    ↓
ScheduleModel.fromMap() parses each schedule
    ↓
Controller updates observable `schedules`
    ↓
UI auto-updates via Obx widget
```

---

### Creating Multi-User Schedule

```
Admin fills form in ScheduleCreateTab
    ↓
Toggles multi-user mode
    ↓
Selects multiple users via dialog
    ↓
Clicks "Create Schedule"
    ↓
AdminScheduleController.createSchedule()
    ↓
AdminScheduleService.createSchedule()
    ↓
Database: INSERT into employee_schedules
    ↓
Returns schedule_id
    ↓
AdminScheduleController.assignMultipleUsersToSchedule()
    ↓
MultiUserScheduleService.assignUsersToSchedule()
    ↓
Supabase RPC: assign_users_to_schedule
    ↓
Database:
  - INSERT into schedule_assignments (for each user)
  - Trigger updates current_participants
    ↓
Success message shown
    ↓
Schedule list refreshes
```

---

### Approving Exchange Request

```
Admin views pending requests in ExchangeRequestScreen
    ↓
Clicks "Approve" button
    ↓
ScheduleExchangeController.manageExchangeRequest(action: 'approve')
    ↓
ScheduleExchangeService.manageExchangeRequest()
    ↓
Supabase RPC: admin_manage_schedule_exchange_request
    ↓
Database:
  - UPDATE schedule_exchange_requests SET status='approved'
  - UPDATE schedule_assignments SET is_active=false WHERE user_id=requester
  - INSERT/UPDATE schedule_assignments for requested_user
  - Trigger updates current_participants
    ↓
Returns success JSON
    ↓
Controller shows success snackbar
    ↓
Request list refreshes
    ↓
Both users' schedules auto-update
```

---

## 💡 Best Practices

### 1. Always Use Services for Database Operations
❌ Don't call Supabase directly from controllers  
✅ Use service layer methods

### 2. Use RPC Functions for Complex Operations
❌ Don't use direct queries for assignments/exchanges  
✅ Use RPC functions that handle validation and data integrity

### 3. Handle Loading States
```dart
isLoading.value = true;
try {
  // operation
} finally {
  isLoading.value = false;
}
```

### 4. Show User Feedback
```dart
Get.snackbar(
  'Success',
  'Operation completed',
  backgroundColor: Colors.green,
  colorText: Colors.white,
);
```

### 5. Parse Dates Consistently
```dart
final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
```

---

## 🆘 Common Issues & Solutions

### Issue: Schedules not loading
**Solution**: Check RPC parameter names (`p_employee_id`, `p_date`)

### Issue: Exchange approval not working
**Solution**: Ensure `update_schedule_exchange_for_multi_user.sql` is applied

### Issue: Multi-user assignment fails
**Solution**: Check `schedule_assignments` table exists and trigger is active

### Issue: Null errors when parsing schedules
**Solution**: Ensure `ScheduleModel.fromMap()` handles missing fields with defaults

---

## 📚 Additional Resources

- [Database Complete Reference](docs/DATABASE_COMPLETE_REFERENCE.md)
- [RPC Quick Reference](docs/RPC_QUICK_REFERENCE.md)
- [Database Schema](docs/database_schema.md)
- [SQL Migration Scripts](sql/README.md)

---

## 🎯 Summary

**Rahiee.AI** follows a clean architecture:

- **Screens** → **Controllers** → **Services** → **Database**
- State management via **GetX**
- Backend via **Supabase RPC functions**
- Multi-user support with **junction tables**
- Real-time updates via **observable variables**

**For questions, always check the documentation first!** 📖

---

**Last Updated**: October 2, 2025


