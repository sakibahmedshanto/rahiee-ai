# User Data Storage in Supabase

## Overview
When a user signs in to the Rahiee AI app, their data is automatically stored and managed in the Supabase database. This document explains how this process works.

## Database Setup

### 1. Run the Database Setup Script
Execute the `database_setup.sql` file in your Supabase SQL Editor to create the necessary tables and policies.

### 2. Update Supabase Credentials
The credentials are already set in `lib/services/supabase_service.dart`:
- **URL**: `https://YOUR_SUPABASE_PROJECT_REF.supabase.co`
- **Anon Key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

## User Data Flow

### Google Sign In
1. **Authentication**: User signs in with Google OAuth
2. **User Creation/Update**: 
   - **New User**: Creates a new user record in the `my_users` table with:
     - Unique employee ID (EMP-XXXXXXXX)
     - Google profile information
     - Default role: 'employee'
     - Creation timestamp
     - Last login timestamp
   - **Existing User**: Updates the existing user's:
     - Last login timestamp
     - Profile image (if changed)

### Email Sign In
1. **Authentication**: User signs in with email/password
2. **Data Update**: Updates the user's last login timestamp in the database
3. **User Retrieval**: Fetches complete user profile from the database

### Email Sign Up
1. **Authentication**: Creates user account in Supabase Auth
2. **Profile Creation**: Creates comprehensive user profile in the `my_users` table
3. **Data Storage**: Stores all user information with proper defaults

## User Data Structure

The `my_users` table contains:

### Required Fields
- `id`: UUID (primary key, matches Supabase Auth user ID)
- `employee_id`: Unique employee identifier
- `username`: User's chosen username
- `email`: User's email address
- `full_name`: User's full name
- `user_role`: 'employee', 'admin', 'ceo', or 'manager'
- `is_active`: Boolean flag for active users

### Optional Fields
- `phone`: Phone number
- `user_img`: Profile image URL
- `department`: User's department
- `position`: Job position
- `work_location`: Work location/office
- `shift_type`: Work shift preference
- `last_login`: Last login timestamp
- `created_on`: Account creation timestamp
- And many more fields for comprehensive user management

## Key Features

### 1. Automatic User Profile Creation
```dart
// When a new user signs in via Google
UserModel userModel = UserModel(
  uId: response.user!.id,
  employeeId: 'EMP-${response.user!.id.substring(0, 8).toUpperCase()}',
  username: userName,
  email: userEmail,
  // ... other fields
);
await _getUserDataController.createUserModel(userModel);
```

### 2. Role-Based Access
- Users with `user_role` of 'admin' or 'ceo' are redirected to admin screens
- Regular employees are directed to the standard landing screen

### 4. Data Validation
- All user data is validated before storage
- Proper error handling for database operations
- Success/failure feedback to users

## Security Features

### Row Level Security (RLS)
- Users can only view/edit their own profile
- Admins can view/edit all user profiles
- Secure data access based on authentication

### Data Privacy
- User passwords are handled by Supabase Auth (not stored in my_users table)
- Sensitive data is protected by RLS policies
- Proper error handling without exposing sensitive information

## Testing

Use the built-in test method to verify database operations:
```dart
bool testResult = await _supabaseService.testUserOperations();
```

## Monitoring

### Success Indicators
- ✅ User data successfully stored in Supabase database
- ✅ User login time updated in Supabase database

### Error Handling
- ⚠️ Failed to update user login time, proceeding anyway
- ❌ Failed to create user profile

## Database Performance

### Indexes
The following indexes are created for optimal performance:
- Email index for quick user lookups
- Employee ID index for unique identification
- User role index for admin queries
- Active status index for filtering
- Department index for organizational queries

## Next Steps

1. **Run Database Setup**: Execute `database_setup.sql` in Supabase
2. **Test Sign In**: Try signing in with Google or email
3. **Verify Data**: Check the `my_users` table in Supabase dashboard
4. **Monitor Logs**: Watch console output for success/error messages

## Troubleshooting

### Common Issues
1. **Table doesn't exist**: Run the database setup script
2. **Permission denied**: Check RLS policies
3. **User not found**: Verify the user ID mapping
4. **Connection issues**: Check Supabase credentials

### Debug Mode
Enable debug prints in `GetUserDataController` to see detailed operation logs.
