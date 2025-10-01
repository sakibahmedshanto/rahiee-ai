# 🗄️ Rahiee.AI Database Schema Reference

## 🔑 Primary Keys & Important Fields

### Main Tables:
- **`my_users`** - Primary key: `id` (UUID), Unique: `employee_id` (VARCHAR)
- **`attendance`** - Primary key: `id` (UUID), Foreign key: `user_id` (UUID) → my_users.id
- **`employee_schedules`** - Primary key: `id` (UUID), Foreign keys: `assigned_user_id`, `actual_user_id` (UUID) → my_users.id
- **`daily_employee_summary`** - Primary key: `id` (UUID), Foreign key: `employee_id` (UUID) → my_users.id
- **`monthly_employee_summary`** - Primary key: `id` (UUID), Foreign key: `employee_id` (UUID) → my_users.id

## 📋 Complete Table Schemas

### `my_users` Table:
- `id` (UUID, PRIMARY KEY) - Main user identifier
- `employee_id` (VARCHAR, UNIQUE) - Employee ID string
- `username` (VARCHAR, NOT NULL)
- `email` (VARCHAR, NOT NULL)
- `full_name` (VARCHAR, NOT NULL)
- `user_role` (VARCHAR, default: 'employee')
- `department` (VARCHAR, default: 'General')
- `position` (VARCHAR, default: 'Employee')
- `is_active` (BOOLEAN, default: true)
- `salary_rate` (NUMERIC)
- `phone`, `user_img`, `work_location`, `shift_type`, etc.

### `attendance` Table:
- `id` (UUID, PRIMARY KEY)
- `user_id` (UUID, FK → my_users.id) ⚠️ **USE THIS, NOT employee_id**
- `schedule_id` (UUID, FK → employee_schedules.id)
- `date` (DATE, NOT NULL)
- `check_in_time`, `check_out_time` (TIMESTAMPTZ)
- `status` (VARCHAR, default: 'pending')
- `total_work_hours`, `overtime_hours`, `net_work_hours` (NUMERIC)
- `reviewed_by` (UUID, FK → my_users.id)
- `payment_status` (VARCHAR, default: 'unpaid')
- Location fields: `latitude`, `longitude`, `location` (TEXT)

### `employee_schedules` Table:
- `id` (UUID, PRIMARY KEY)
- `assigned_user_id` (UUID, FK → my_users.id) - Originally assigned user
- `actual_user_id` (UUID, FK → my_users.id) - User who actually worked
- `created_by_admin_id` (UUID, FK → my_users.id)
- `title` (VARCHAR, NOT NULL)
- `start_date_time`, `end_date_time` (TIMESTAMPTZ, NOT NULL)
- `department`, `location` (VARCHAR, NOT NULL)
- `status` (VARCHAR, default: 'active')
- `is_active` (BOOLEAN, default: true)

## 🔧 Key Database Functions (RPC)
## 🔧 Key Database Functions (RPC)

### ✅ Currently Used Functions:
1. `admin_review_attendance` - Returns JSON
2. `admin_update_attendance_status` - Returns JSON  
3. `can_check_in_for_schedule` - Returns JSON
4. `check_schedule_conflict` - Returns boolean
5. `complete_attendance_checkout` - Returns JSON
6. `create_pending_attendance` - Returns JSON
7. `get_admin_attendance_records` - Returns JSON
8. `get_admin_schedule_report` - Returns record
9. `get_attendance_for_date_range_detailed` - Returns record
10. `get_attendance_dashboard_summary` - Returns JSON
11. `get_attendance_summary_for_period` - Returns JSON
12. `get_pending_attendance_for_admin_review` - Returns record
13. `get_schedule_attendance_status` - Returns JSON
14. `get_schedules_with_attendance_status` - Returns JSON
18. `calculate_attendance_metrics` - Used by trigger

### 🆕 New Schedule Management Functions:
19. `admin_create_schedule` - Returns JSON - Creates new schedules with validation
20. `admin_get_schedules` - Returns JSON - Lists schedules with filtering
21. `admin_update_schedule` - Returns JSON - Updates existing schedules
22. `admin_delete_schedule` - Returns JSON - Soft/hard deletes schedules
23. `admin_get_available_users` - Returns JSON - Gets users available for assignment

### ❌ Missing Functions (Called in code but don't exist):
- `bulk_update_attendance_status` - Need to create this!

### 🔒 Trigger Functions (Don't delete):
- `log_attendance_changes` - Trigger on attendance table
- `update_attendance_summaries` - Trigger on attendance table
- `update_updated_at_column` - Trigger on employee_schedules, my_users tables
- `validate_attendance_schedule` - Trigger on attendance table
- `calculate_attendance_metrics` - Trigger on attendance table

## ⚠️ Common Mistakes to Avoid:

### Database Field Mistakes:
- ❌ Don't use `employee_id` as FK - use `user_id` (UUID)
- ❌ Don't assume `my_users.user_id` exists - it's `my_users.id`
- ❌ The `employee_id` field in `my_users` is VARCHAR, not UUID
- ❌ In summary tables, FK is `employee_id` but points to `my_users.id`

### Function Mistakes:
- ❌ Don't create duplicate functions - check existing ones first
- ❌ Don't call `bulk_update_attendance_status` until it's created
- ❌ Don't delete trigger functions without removing triggers first

### Table Relationship Mistakes:
```sql
-- ✅ CORRECT:
attendance.user_id → my_users.id
employee_schedules.assigned_user_id → my_users.id
daily_employee_summary.employee_id → my_users.id

-- ❌ WRONG:
attendance.employee_id (doesn't exist)
any_table.user_id → my_users.user_id (doesn't exist)
```

## 🚀 How to Work Efficiently:

1. **Always check this file first** before making DB assumptions
2. **Use MCP to verify** table structure if unsure:
   ```sql
   SELECT column_name, data_type, is_nullable 
   FROM information_schema.columns 
   WHERE table_name = 'your_table' AND table_schema = 'public';
   ```
3. **Test functions exist** before calling them:
   ```sql
   SELECT routine_name FROM information_schema.routines 
   WHERE routine_name = 'your_function' AND routine_schema = 'public';
   ```