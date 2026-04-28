# Changelog

All notable changes to Rahiee.AI will be documented in this file.

## [1.1.0] - 2025-12-07

### Added
- **Account Deletion Feature** - Users can now permanently delete their accounts from the Profile screen
  - Direct in-app deletion with confirmation dialog
  - Comprehensive data removal (attendance, schedules, payments, notifications, profile)
  - Meets Apple App Store requirements for account deletion
- **Admin Account Management** - Administrators can delete employee accounts from Employee Management
  - Detailed warning dialog before deletion
  - Automatic employee list refresh after deletion
- **Auto-refresh Data** - App automatically loads fresh data when opened
  - Schedule screen refreshes on app open
  - Attendance history loads automatically
  - Notifications sync on open
  - Admin dashboard updates automatically
- **Tab Switch Refresh** - Data automatically refreshes when switching between tabs
  - Employee app refreshes data on tab switch
  - Admin app refreshes relevant data for each tab

### Improved
- **Database Performance** - Added DELETE policies for all related tables
  - Proper foreign key constraint handling
  - RLS policies for secure account deletion
- **Controller Persistence** - Controllers now persist across tab switches
  - Reduced unnecessary data reloading
  - Better memory management
- **Error Handling** - Enhanced error messages and user feedback
- **User Experience** - Loading indicators and confirmation dialogs

### Fixed
- Foreign key constraint violations during account deletion
- Data not loading automatically on app open
- Controller recreation on tab switches
- Missing RLS policies for user data deletion

### Security
- Row Level Security policies for account deletion
- Proper authentication checks before deletion
- Secure data removal process

## [1.0.0] - Initial Release

### Added
- Employee schedule management
- Attendance check-in/check-out with location verification
- Uniform verification system
- Real-time notifications
- Admin dashboard with analytics
- Employee management
- Attendance tracking and approval
- Schedule creation and assignments
- Payment tracking
- Summary reports
