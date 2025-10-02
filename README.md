# 🚀 Rahiee.AI - Employee Schedule & Attendance Management System

> **A comprehensive Flutter-based schedule and attendance management system with multi-user support, real-time tracking, and schedule exchange capabilities.**

---

## 📖 Quick Navigation

### 🎯 **Getting Started**
- [Project Structure](PROJECT_STRUCTURE.md) - Understand the codebase organization
- [Setup Instructions](#setup-instructions) - Get the app running

### 📚 **Database Documentation**
- [Database Complete Reference](docs/DATABASE_COMPLETE_REFERENCE.md) - **START HERE** for database info
- [RPC Quick Reference](docs/RPC_QUICK_REFERENCE.md) - Fast lookup for RPC functions
- [Database Schema](docs/database_schema.md) - Quick schema overview

### 🔧 **SQL Migrations**
- [SQL Migration Guide](sql/README.md) - How to set up the database

### 🧹 **Maintenance**
- [Cleanup Summary](CLEANUP_SUMMARY.md) - Recent cleanup operations

---

## ✨ Key Features

### 👥 Multi-User Schedule Assignment
- Admins can assign multiple employees to a single schedule
- Set minimum and maximum participant limits
- Real-time participant count tracking
- Each user can mark their own attendance

### 🔄 Schedule Exchange System
- Employees can request to swap schedules with others
- Admin approval required for security
- Automatic validation of conflicts
- Full audit trail of exchanges

### 📍 Geolocation Attendance
- GPS-based check-in and check-out
- Location verification for attendance
- Automatic work duration calculation
- Real-time attendance status

### 📊 Admin Dashboard
- Complete schedule management
- Exchange request review and approval
- Attendance monitoring
- User management

### 🔒 Security
- Row Level Security (RLS) on all tables
- Role-based access control (Employee, Admin, Manager, CEO)
- Secure RPC functions for operations
- Authentication via Supabase

---

## 🛠️ Tech Stack

- **Frontend**: Flutter (Dart)
- **State Management**: GetX
- **Backend**: Supabase (PostgreSQL)
- **Authentication**: Supabase Auth
- **Database**: PostgreSQL with RPC functions
- **Geolocation**: Flutter Geolocator package

---

## 📁 Project Structure

```
rahiee_ai/
├── lib/
│   ├── controllers/         # GetX state management
│   ├── models/              # Data models
│   ├── screens/             # UI screens
│   ├── services/            # Business logic & API calls
│   └── utils/               # Utilities & constants
│
├── sql/                     # Database migration scripts
├── docs/                    # Documentation
└── README.md                # This file
```

**For detailed structure, see [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)**

---

## 🚀 Setup Instructions

### Prerequisites

- Flutter SDK (3.0+)
- Dart SDK
- Supabase account
- iOS/Android development environment

### 1. Clone Repository

```bash
git clone <repository-url>
cd rahiee_ai
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Supabase

1. Create a Supabase project at [supabase.com](https://supabase.com)
2. Update `lib/services/supabase_service.dart` with your credentials:

```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

### 4. Set Up Database

Run the SQL migration scripts in order:

```bash
# Using Supabase SQL Editor, run in this order:
1. sql/multi_user_schedule_system.sql
2. sql/schedule_exchange_functions.sql
3. sql/update_schedule_exchange_for_multi_user.sql
4. sql/attendance_functions.sql
5. sql/comprehensive_attendance_system.sql
```

**For detailed setup, see [sql/README.md](sql/README.md)**

### 5. Run the App

```bash
flutter run
```

---

## 📚 Documentation Guide

### 🎯 **I need to...**

#### **Understand the database structure**
→ Read [docs/DATABASE_COMPLETE_REFERENCE.md](docs/DATABASE_COMPLETE_REFERENCE.md)

#### **Find an RPC function quickly**
→ Check [docs/RPC_QUICK_REFERENCE.md](docs/RPC_QUICK_REFERENCE.md)

#### **Set up the database**
→ Follow [sql/README.md](sql/README.md)

#### **Understand the code structure**
→ Read [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)

#### **Avoid common mistakes**
→ Check [docs/database_schema.md](docs/database_schema.md)

#### **See what was cleaned up recently**
→ Review [CLEANUP_SUMMARY.md](CLEANUP_SUMMARY.md)

---

## 🔑 Key Concepts

### Multi-User Schedules

A single schedule can have multiple employees assigned:

```dart
// Admin creates schedule and assigns 3 users
await AdminScheduleController.createSchedule(...);
await AdminScheduleController.assignMultipleUsersToSchedule(
  scheduleId: scheduleId,
  userIds: ['user1', 'user2', 'user3'],
);

// Each user sees the schedule in their list
// Each user can mark their own attendance
```

### Schedule Exchange Flow

```
Employee requests exchange
    ↓
Admin reviews request
    ↓
Admin approves
    ↓
System updates assignments
    ↓
Both users' schedules update
```

### Attendance Flow

```
Employee opens schedule
    ↓
Clicks "Check In" (GPS captured)
    ↓
Works their shift
    ↓
Clicks "Check Out" (GPS captured)
    ↓
System calculates work duration
```

---

## 🗄️ Database Overview

### Core Tables

1. **`my_users`** - User accounts
2. **`employee_schedules`** - Schedule definitions
3. **`schedule_assignments`** - Multi-user assignments (junction table)
4. **`attendance`** - Attendance records
5. **`schedule_exchange_requests`** - Exchange requests

### Key RPC Functions

- `get_schedules_with_attendance_status()` - Fetch schedules with attendance
- `assign_users_to_schedule()` - Assign multiple users
- `create_schedule_exchange_request()` - Request schedule exchange
- `admin_manage_schedule_exchange_request()` - Approve/reject exchange
- `check_in()` / `check_out()` - Attendance tracking

**For complete list, see [docs/RPC_QUICK_REFERENCE.md](docs/RPC_QUICK_REFERENCE.md)**

---

## 🎯 Common Operations

### Load User Schedules

```dart
final response = await supabase.rpc(
  'get_schedules_with_attendance_status',
  params: {
    'p_employee_id': userId,
    'p_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
  },
);
```

### Assign Multiple Users to Schedule

```dart
final result = await supabase.rpc(
  'assign_users_to_schedule',
  params: {
    'p_schedule_id': scheduleId,
    'p_user_ids': ['user1-uuid', 'user2-uuid'],
    'p_admin_id': adminId,
  },
);
```

### Create Exchange Request

```dart
final result = await supabase.rpc(
  'create_schedule_exchange_request',
  params: {
    'p_requester_user_id': currentUserId,
    'p_schedule_id': scheduleId,
    'p_requested_user_id': targetUserId,
    'p_request_reason': 'Family emergency',
    'p_request_notes': null,
    'p_request_type': 'exchange',
    'p_expires_in_days': 7,
  },
);
```

---

## ⚠️ Important Notes

### Database Best Practices

1. ✅ **Always use RPC functions** for complex operations
2. ✅ **Use `schedule_assignments`** for multi-user queries (not just `assigned_user_id`)
3. ✅ **Foreign keys point to `my_users.id`** (UUID), never `employee_id` (TEXT)
4. ✅ **Date format**: `YYYY-MM-DD` for date parameters
5. ✅ **Error handling**: All RPCs return JSON with `success` field

### Common Mistakes to Avoid

❌ Using `employee_id` as foreign key (use `user_id` instead)  
❌ Direct database inserts without validation (use RPCs)  
❌ Checking only `assigned_user_id` for multi-user schedules  
❌ Wrong date formats  

**For detailed mistakes, see [docs/database_schema.md](docs/database_schema.md)**

---

## 🧹 Recent Cleanup (Oct 2, 2025)

The codebase was recently cleaned up:

- 🔽 **51% reduction** in total files
- 📚 **1,880+ lines** of new documentation
- ✅ **Zero technical debt**
- ✅ **All unused code removed**

**See [CLEANUP_SUMMARY.md](CLEANUP_SUMMARY.md) for details**

---

## 🤝 Contributing

### Before Making Changes

1. Read [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) to understand the codebase
2. Check [docs/DATABASE_COMPLETE_REFERENCE.md](docs/DATABASE_COMPLETE_REFERENCE.md) for database info
3. Follow existing patterns and conventions
4. Test thoroughly before committing

### Adding New Features

1. Update services first (business logic)
2. Update controllers (state management)
3. Update UI screens
4. Add/update RPC functions if needed
5. Update documentation

---

## 📞 Support

### Documentation Resources

- 📚 [Complete Database Reference](docs/DATABASE_COMPLETE_REFERENCE.md)
- ⚡ [RPC Quick Reference](docs/RPC_QUICK_REFERENCE.md)
- 📋 [Database Schema](docs/database_schema.md)
- 🏗️ [Project Structure](PROJECT_STRUCTURE.md)
- 🗄️ [SQL Migration Guide](sql/README.md)

### Common Issues

For troubleshooting common issues:
- Check [docs/database_schema.md](docs/database_schema.md) - Common Mistakes section
- Check [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) - Common Issues & Solutions section
- Check [docs/DATABASE_COMPLETE_REFERENCE.md](docs/DATABASE_COMPLETE_REFERENCE.md) - Troubleshooting section

---

## 📝 License

[Your License Here]

---

## 🎉 Credits

Developed with ❤️ for efficient employee management

---

**Last Updated**: October 2, 2025

---

## 📌 Quick Links Summary

| Documentation | Purpose | Link |
|--------------|---------|------|
| **Complete Database Reference** | Full database documentation | [docs/DATABASE_COMPLETE_REFERENCE.md](docs/DATABASE_COMPLETE_REFERENCE.md) |
| **RPC Quick Reference** | Fast RPC lookup | [docs/RPC_QUICK_REFERENCE.md](docs/RPC_QUICK_REFERENCE.md) |
| **Database Schema** | Quick schema reference | [docs/database_schema.md](docs/database_schema.md) |
| **Project Structure** | Code organization guide | [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) |
| **SQL Migration Guide** | Database setup | [sql/README.md](sql/README.md) |
| **Cleanup Summary** | Recent cleanup details | [CLEANUP_SUMMARY.md](CLEANUP_SUMMARY.md) |

**Start with [docs/DATABASE_COMPLETE_REFERENCE.md](docs/DATABASE_COMPLETE_REFERENCE.md) if you're new to the project!** 🚀
