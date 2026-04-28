# Employee Attendance History System - User Guide

## Overview
The Employee Attendance History system allows employees to view their past attendance records with **lazy loading** (infinite scroll) and filtering capabilities.

## Features

### ✅ What's Implemented
1. **Lazy Loading**: Automatically loads more records as you scroll
2. **Pull to Refresh**: Swipe down to reload data
3. **Status Filtering**: Filter by attendance status
4. **Detailed Cards**: Shows check-in/out times, duration, location, and flags
5. **Visual Indicators**: 
   - Status badges with icons
   - Late arrival warnings
   - Early departure warnings
   - Work duration color coding

### 📊 Displayed Information
Each attendance card shows:
- **Schedule title** and **status badge**
- **Date** and **Location**
- **Check-in time** and **Check-out time**
- **Work duration** (color-coded: green for overtime, red for undertime)
- **Warning badges** for late arrival or early departure

## How to Use

### Accessing the Screen
Navigate to the Attendance History screen from your app's main menu or navigation drawer.

### Filtering Records
1. Tap the **filter icon** (☰) in the app bar
2. Select a status:
   - **All**: Show all records
   - **Pending**: Awaiting review
   - **Pending Checkout**: Currently checked in
   - **Completed**: Finished shifts
   - **Granted**: Approved for payment
   - **Approved**: Admin approved
   - **Rejected**: Not approved
   - **Not Granted**: Payment not granted
   - **Unusual**: Flagged as unusual
   - **Cancelled**: Cancelled shifts

### Scrolling Through History
- The system loads **20 records** at a time
- Scroll to the bottom to automatically load more
- A loading indicator appears while fetching

### Refreshing Data
- **Pull down** from the top of the list to refresh

## Troubleshooting

### "No attendance records" shown

Run the app and check the **debug console** for detailed logs. Look for:

#### 1. **Check User Authentication**
```
DEBUG: Current user ID: <your-user-id>
```
- If it says `NOT LOGGED IN`, you need to log in first
- Copy the user ID to compare with database records

#### 2. **Check Query Execution**
```
DEBUG: Querying attendance for user_id: <id>
DEBUG: Response count: X
```
- If count is 0, check the following reasons below

#### 3. **Common Issues**

**Issue**: User ID mismatch
```
DEBUG: ⚠️ NO RECORDS FOUND!
DEBUG: User ID mismatch (check if user is logged in)
```
**Solution**: 
- Verify the logged-in user has attendance records in the database
- Check Supabase database: `SELECT * FROM attendance WHERE user_id = '<your-id>';`

**Issue**: RLS (Row Level Security) blocking access
```
DEBUG: RLS policies blocking access
```
**Solution**: 
- Check Supabase RLS policies for the `attendance` table
- Ensure employees can read their own attendance records
- Recommended policy:
```sql
CREATE POLICY "Users can view own attendance"
ON attendance FOR SELECT
USING (auth.uid() = user_id);
```

**Issue**: No data in database
**Solution**: Create attendance records by:
1. Checking in to a schedule
2. Checking out from a schedule
3. Having an admin create attendance records

#### 4. **Check Database Connection**
```
DEBUG: ERROR in direct query: <error message>
```
- Check internet connection
- Verify Supabase project is active
- Check Supabase credentials in your app

### Getting Help

If you see errors in the logs:

1. **Copy the debug output** from console
2. **Check the error message** for specific issues
3. **Verify database setup**:
   - Table `attendance` exists
   - Column `user_id` matches auth.uid()
   - RLS policies allow user access
   
4. **Test with Supabase dashboard**:
   ```sql
   -- Check if attendance records exist
   SELECT COUNT(*) FROM attendance;
   
   -- Check specific user's records
   SELECT * FROM attendance 
   WHERE user_id = '<paste-user-id-from-logs>';
   ```

## Technical Details

### Files Modified/Created
1. **Service**: `lib/services/attendance_history_service.dart`
   - Handles data fetching from Supabase
   - Implements pagination logic
   - Uses direct database queries (efficient and reliable)

2. **Controller**: `lib/controllers/attendance_history_controller.dart`
   - Manages state with GetX
   - Handles user actions (filter, refresh, pagination)
   - Coordinates with service layer

3. **Screen**: `lib/screens/attendance_history_screen/attendance_history_screen.dart`
   - UI implementation
   - Displays attendance cards
   - Handles scroll events for lazy loading

### Database Table: `attendance`

Key columns used:
- `id`: Unique identifier
- `user_id`: Employee UUID (foreign key to `my_users`)
- `schedule_id`: Reference to schedule
- `date`: Attendance date
- `check_in_time`: Check-in timestamp
- `check_out_time`: Check-out timestamp
- `status`: Current status (pending, granted, rejected, etc.)
- `total_work_hours`: Calculated work hours
- `is_late`: Late arrival flag
- `is_early_departure`: Early departure flag
- `location`: Work location
- And many more...

### Data Flow
1. User opens Attendance History screen
2. Controller initializes and calls service
3. Service queries Supabase `attendance` table
4. Data is filtered by `user_id`
5. Results are transformed and returned
6. Controller updates UI with records
7. User scrolls → More records loaded automatically

## Status Indicators

| Status | Icon | Color | Meaning |
|--------|------|-------|---------|
| Completed | ✓ | Green | Shift completed successfully |
| Pending | ⏱ | Orange | Awaiting review |
| Pending Checkout | ⏲ | Blue | Currently checked in |
| Granted | ✓ | Teal | Approved for payment |
| Approved | 👍 | Green | Admin approved |
| Rejected | ✗ | Red | Not approved |
| Not Granted | ⊘ | Red | Payment denied |
| Unusual | ⚠ | Purple | Flagged for review |
| Appealed | ⚖ | Indigo | Under appeal |
| Cancelled | ✗ | Grey | Cancelled |

## Debug Mode

All debug logs start with `DEBUG:` prefix. Enable console logging in your development environment to see:

- User authentication status
- Query parameters
- Response counts
- Error messages
- Performance metrics

### Example Debug Output
```
DEBUG: ========== CONTROLLER LOADING ATTENDANCE ==========
DEBUG: User ID: 883d252d-83d7-4ce5-a1ef-f34e76f5189d
DEBUG: Selected status: ALL
DEBUG: Current offset: 0
DEBUG: ========== ATTENDANCE QUERY DEBUG ==========
DEBUG: Querying attendance for user_id: 883d252d-83d7-4ce5-a1ef-f34e76f5189d
DEBUG: Status filter: NONE (all statuses)
DEBUG: Query executed successfully!
DEBUG: ✅ Found 8 attendance records
DEBUG: First record date: 2025-10-02
```

## Next Steps

Once the system is working:
1. Remove or reduce debug logging for production
2. Implement analytics tracking
3. Add export functionality (CSV/PDF)
4. Consider adding date range pickers
5. Add summary statistics at the top

