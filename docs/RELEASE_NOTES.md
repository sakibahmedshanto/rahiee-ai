# Release Notes - Version 1.1.0

## App Store Release Notes

### What's New in Version 1.1.0

✨ **NEW FEATURES**
• Account Deletion - Users can now delete their accounts directly from the app (Profile > Delete Account)
• Auto-refresh - App automatically loads latest data when opened or when switching tabs
• Admin Account Management - Administrators can manage and delete employee accounts
• Enhanced Security - Improved data protection with Row Level Security policies

🔧 **IMPROVEMENTS**
• Better data synchronization across all screens
• Improved app performance and loading times
• Enhanced error handling and user feedback
• Optimized database operations
• Reduced unnecessary data reloading

🐛 **BUG FIXES**
• Fixed data loading issues on app startup
• Improved database performance
• Enhanced app stability
• Resolved controller persistence issues

---

## TestFlight Beta Notes

### Testing Focus Areas

**Critical - Account Deletion:**
1. Navigate to Profile tab
2. Scroll down and tap "Delete Account"
3. Read warnings and type "DELETE" to confirm
4. Verify account is deleted and you're logged out
5. Confirm you cannot log in with deleted credentials

**Auto-Refresh Testing:**
1. Open the app fresh (force quit first)
2. Verify Schedule screen shows latest data
3. Switch to Attendance History - verify data loads
4. Switch to Notifications - verify notifications load
5. Switch back to Schedule - verify data refreshes

**Admin Testing (Admin accounts only):**
1. Login as admin
2. Navigate to Employees tab
3. Tap three dots on employee card
4. Select "Delete Account"
5. Confirm deletion
6. Verify employee is removed from list

### Known Issues
None at this time.

### Privacy & Security
- All account deletion is permanent and cannot be undone
- User data is completely removed from database
- Meets Apple's account deletion requirements
- Enhanced RLS policies for data security

---

## Privacy Policy Update Required

Add this section to your Privacy Policy:

### ACCOUNT DELETION

Users can request deletion of their account and associated data at any time through the app.

**How to Delete Your Account:**
1. Open the Rahiee.AI app
2. Navigate to the Profile tab
3. Scroll to the bottom and tap "Delete Account"
4. Read the deletion warnings carefully
5. Type "DELETE" to confirm
6. Tap "Delete Account" button

**What Gets Deleted:**
Upon account deletion, the following data will be permanently removed:
- Personal information (name, email, phone number, employee ID)
- Attendance records and history
- Schedule assignments and preferences
- Payment transaction records
- Notification history
- All associated user data

**Important Notes:**
- Deletion is permanent and cannot be undone
- You will be immediately logged out
- You cannot create a new account with the same email
- Backup any important data before deletion

**Need Help?**
For assistance with account deletion or questions about your data, contact our support team:
- Email: support@rahiee.ai
- In-app: Settings > Help & Support

**Data Retention:**
We do not retain any personal data after account deletion. Some anonymized, aggregated data may be kept for analytics purposes but cannot be linked back to you.

---

## Support Documentation

### Frequently Asked Questions

**Q: How do I delete my account?**
A: Go to Profile > Delete Account, read the warnings, type "DELETE" to confirm, and tap the delete button.

**Q: Can I recover my account after deletion?**
A: No, account deletion is permanent and cannot be undone.

**Q: What happens to my attendance records?**
A: All your attendance records are permanently deleted along with your account.

**Q: How long does deletion take?**
A: Account deletion is immediate. You'll be logged out as soon as the process completes.

**Q: Will my admin see that I deleted my account?**
A: Your profile will be removed from the employee list. Admins won't have access to your deleted data.

**Q: Can I use the same email to create a new account?**
A: After deletion, you can create a new account, but your previous data cannot be recovered.

---

## Developer Notes

### Version Information
- Version: 1.1.0
- Build: 2
- Release Date: December 7, 2025
- Minimum iOS: 12.0
- Tested on: iOS 16.0, 17.0

### Technical Changes
- Added account deletion service
- Implemented RLS policies for secure deletion
- Added auto-refresh on app open and tab switches
- Optimized controller lifecycle management
- Enhanced error handling

### Database Migrations
- Added DELETE policies for user data tables
- Updated foreign key constraints handling
- Implemented cascading deletion logic

### API Changes
None - All changes are backward compatible

### Breaking Changes
None

---

## Submission Checklist

Before submitting to App Store:

**Build & Version**
- [x] Version updated to 1.1.0+2
- [ ] App builds successfully without errors
- [ ] No compiler warnings
- [ ] All dependencies up to date

**Testing**
- [ ] Account deletion tested on physical device
- [ ] Auto-refresh verified on all screens
- [ ] Admin deletion tested
- [ ] No crashes on any screen
- [ ] All features working as expected

**Documentation**
- [x] Release notes prepared
- [x] CHANGELOG updated
- [ ] Privacy policy updated with account deletion
- [ ] App Store description updated (if needed)
- [ ] Screenshots updated (if UI changed)

**App Store Connect**
- [ ] Build uploaded to App Store Connect
- [ ] Build selected for new version
- [ ] Release notes added
- [ ] Privacy details updated
- [ ] Account deletion method specified
- [ ] Support URL verified
- [ ] Privacy policy URL verified

**Legal & Compliance**
- [ ] Privacy policy includes account deletion
- [ ] Support email working: support@rahiee.ai
- [ ] Account deletion meets Apple requirements
- [ ] GDPR compliance verified
- [ ] Data retention policy updated

**Final Steps**
- [ ] TestFlight testing completed
- [ ] Beta feedback addressed
- [ ] Submit for App Store review
- [ ] Monitor submission status
