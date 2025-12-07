# App Store Submission Checklist
## Rahiee.AI Version 1.1.0+2

### ✅ Pre-Build Checklist

#### Version & Build
- [x] Version number updated to 1.1.0+2 in pubspec.yaml
- [ ] CHANGELOG.md updated with all changes
- [ ] No debug code or console logs in production code
- [ ] All TODO comments addressed or documented

#### Code Quality
- [ ] `flutter analyze` passes with no errors
- [ ] All compiler warnings resolved
- [ ] No deprecated API usage
- [ ] Code properly formatted (`flutter format .`)

#### Dependencies
- [ ] All dependencies are up to date
- [ ] No dependency conflicts
- [ ] All required permissions declared in Info.plist
- [ ] Firebase configuration files present

---

### 🧪 Testing Checklist

#### Core Features - User Side
- [ ] **Login/Authentication**
  - [ ] Email/password login works
  - [ ] Error messages display correctly
  - [ ] "Remember me" functionality works

- [ ] **Schedule Screen**
  - [ ] Schedules load automatically on app open
  - [ ] Can view schedule details
  - [ ] Check-in button appears when appropriate
  - [ ] Location permission request works

- [ ] **Attendance**
  - [ ] Check-in with location verification works
  - [ ] Uniform photo upload works
  - [ ] Check-out functionality works
  - [ ] Attendance history loads automatically

- [ ] **Notifications**
  - [ ] Notifications load on tab open
  - [ ] Can mark notifications as read
  - [ ] Push notifications work
  - [ ] Notification badge updates

- [ ] **Profile**
  - [ ] Profile information displays correctly
  - [ ] Logout works properly
  - [ ] Settings accessible

#### Critical Feature - Account Deletion
- [ ] **User Account Deletion**
  - [ ] "Delete Account" button visible in Profile
  - [ ] Warning dialog displays with all information
  - [ ] Confirmation text input works
  - [ ] Deletion completes successfully
  - [ ] User is logged out after deletion
  - [ ] Cannot log in with deleted credentials
  - [ ] All user data removed from database

- [ ] **Admin Account Deletion**
  - [ ] Admin can see delete option for employees
  - [ ] Warning dialog shows employee details
  - [ ] Deletion confirmation required
  - [ ] Employee removed from list after deletion
  - [ ] All related data deleted

#### Auto-Refresh Features
- [ ] App loads data automatically on first open
- [ ] Schedule refreshes when switching to tab
- [ ] Attendance history refreshes on tab switch
- [ ] Notifications refresh on tab switch
- [ ] No manual refresh needed

#### Admin Features
- [ ] **Dashboard**
  - [ ] Loads automatically on app open
  - [ ] Real-time stats display correctly
  - [ ] Charts render properly
  - [ ] Quick actions work

- [ ] **Employee Management**
  - [ ] Employee list loads automatically
  - [ ] Search functionality works
  - [ ] Department filters work
  - [ ] Employee details display correctly
  - [ ] Can delete employee accounts

- [ ] **Attendance Management**
  - [ ] Pending attendance loads automatically
  - [ ] Can approve/reject attendance
  - [ ] Attendance table displays correctly
  - [ ] Filters work properly

- [ ] **Schedule Management**
  - [ ] Can create new schedules
  - [ ] Can assign employees to schedules
  - [ ] Schedule list displays correctly

- [ ] **Summary Reports**
  - [ ] Reports load automatically
  - [ ] Data displays correctly
  - [ ] Export functionality works (if available)

#### Device Testing
- [ ] Tested on iPhone (various models)
- [ ] Tested on iPad (if supported)
- [ ] Tested on iOS 16.x
- [ ] Tested on iOS 17.x
- [ ] Portrait orientation works
- [ ] Landscape orientation works (if supported)
- [ ] Dark mode works properly
- [ ] Light mode works properly

#### Performance
- [ ] App launches quickly (< 3 seconds)
- [ ] No memory leaks
- [ ] Smooth scrolling on all screens
- [ ] No frame drops or lag
- [ ] Images load efficiently
- [ ] Network requests timeout gracefully

#### Error Handling
- [ ] Network errors handled gracefully
- [ ] No unhandled exceptions
- [ ] User-friendly error messages
- [ ] Offline mode behavior acceptable
- [ ] Permission denials handled properly

---

### 📱 Build & Archive Checklist

#### Build Process
- [ ] Run `flutter clean`
- [ ] Run `flutter pub get`
- [ ] Run `flutter analyze` (no errors)
- [ ] Run build script: `./build_ios.sh ipa`
- [ ] Build completes without errors
- [ ] No warnings in Xcode

#### Xcode Configuration
- [ ] Open `ios/Runner.xcworkspace` in Xcode
- [ ] Select "Any iOS Device (arm64)" as destination
- [ ] Signing & Capabilities configured
  - [ ] Team selected
  - [ ] Bundle Identifier correct
  - [ ] Provisioning profile valid
  - [ ] Push Notifications enabled
  - [ ] Background Modes configured (if needed)
- [ ] Version shows 1.1.0
- [ ] Build number shows 2

#### Archive Creation
- [ ] Product > Clean Build Folder
- [ ] Product > Archive
- [ ] Archive completes successfully
- [ ] Archive appears in Organizer
- [ ] Validate App (no errors)
- [ ] Distribute App to App Store Connect
- [ ] Upload completes successfully

---

### 📋 App Store Connect Checklist

#### Version Information
- [ ] Create new version 1.1.0 in App Store Connect
- [ ] Select uploaded build (may take 5-10 mins to process)
- [ ] Build processing completes without issues

#### App Information
- [ ] **What's New** - Release notes added:
```
✨ NEW FEATURES
• Account Deletion - Delete your account directly from the app
• Auto-refresh - Latest data loads automatically
• Admin Account Management

🔧 IMPROVEMENTS
• Better data synchronization
• Improved performance
• Enhanced security

🐛 BUG FIXES
• Fixed data loading issues
• Improved stability
```

#### Privacy & Data
- [ ] **Account Deletion Information Updated**
  - [ ] Method: Available in the app
  - [ ] Location: Profile > Delete Account
  - [ ] Description provided
  - [ ] Support email: support@rahiee.ai

- [ ] **Privacy Policy**
  - [ ] URL accessible: [Your privacy policy URL]
  - [ ] Includes account deletion section
  - [ ] Up to date with current practices

- [ ] **Support URL**
  - [ ] URL accessible: [Your support URL]
  - [ ] Contains contact information
  - [ ] Has FAQ about account deletion

#### App Review Information
- [ ] **Contact Information**
  - [ ] Name provided
  - [ ] Phone number provided
  - [ ] Email provided

- [ ] **Demo Account** (if required)
  - [ ] Test employee account credentials
  - [ ] Test admin account credentials
  - [ ] Accounts have sample data

- [ ] **Notes for Reviewer**
```
Version 1.1.0 adds Apple-required account deletion feature.

To test account deletion:
1. Login with demo employee account
2. Navigate to Profile tab
3. Scroll to bottom, tap "Delete Account"
4. Type "DELETE" to confirm
5. Account will be permanently deleted

Admin can also delete employee accounts:
1. Login with admin account
2. Go to Employees tab
3. Tap three dots on employee card
4. Select "Delete Account"

Both deletion methods work identically and remove all user data.

Test Accounts:
Employee: [email] / [password]
Admin: [email] / [password]
```

#### Screenshots & Media
- [ ] Screenshots are current (update if UI changed)
- [ ] App Preview video (optional but recommended)
- [ ] All required screenshot sizes provided
- [ ] Dark mode screenshots (if applicable)

#### Pricing & Availability
- [ ] Price tier set correctly
- [ ] Countries/regions selected
- [ ] Release schedule configured

---

### 🔒 Legal & Compliance Checklist

#### Privacy Compliance
- [ ] GDPR compliance verified
- [ ] CCPA compliance verified (if applicable)
- [ ] Data retention policy documented
- [ ] User consent mechanisms in place

#### Account Deletion Compliance
- [ ] Meets Apple's account deletion requirements
- [ ] In-app deletion available
- [ ] Deletion is complete and permanent
- [ ] Support contact available
- [ ] Process is clear and accessible

#### Terms & Conditions
- [ ] Terms of Service accessible
- [ ] Privacy Policy accessible
- [ ] Updated for new features
- [ ] Legally reviewed (recommended)

---

### 📝 Documentation Checklist

#### User Documentation
- [ ] Help section updated (if exists)
- [ ] FAQ includes account deletion
- [ ] User guide updated
- [ ] Support articles published

#### Developer Documentation
- [ ] README updated
- [ ] CHANGELOG complete
- [ ] API documentation current
- [ ] Database schema documented

---

### 🚀 Pre-Submission Final Steps

#### Final Review
- [ ] All checklist items above completed
- [ ] App tested on physical device (not just simulator)
- [ ] Account deletion tested with real test account
- [ ] No crashes or critical bugs
- [ ] Performance is acceptable
- [ ] UI/UX is polished

#### Backup & Version Control
- [ ] All code committed to git
- [ ] Tagged release: `git tag v1.1.0`
- [ ] Pushed to remote: `git push origin v1.1.0`
- [ ] Database backup created (if applicable)

#### Team Communication
- [ ] Team notified of submission
- [ ] Support team prepared for potential user questions
- [ ] Marketing team has release notes
- [ ] Monitoring systems ready

#### Submit for Review
- [ ] Review all information one final time
- [ ] Click "Submit for Review" in App Store Connect
- [ ] Confirm submission
- [ ] Monitor email for App Store communications
- [ ] Set calendar reminder to check status in 24 hours

---

### 📞 Post-Submission Checklist

#### Monitoring
- [ ] Check App Store Connect daily for status updates
- [ ] Monitor email for Apple communications
- [ ] Respond to any Apple questions within 24 hours
- [ ] Check crash reports in App Store Connect

#### If Rejected
- [ ] Read rejection reason carefully
- [ ] Make necessary changes
- [ ] Test fixes thoroughly
- [ ] Resubmit with explanation of changes
- [ ] Follow up if rejection seems incorrect

#### If Approved
- [ ] Verify app is live on App Store
- [ ] Test download and installation
- [ ] Monitor initial reviews
- [ ] Respond to user feedback
- [ ] Prepare for next version

---

## 📊 Submission Timeline

**Expected Timeline:**
- Upload build: ~10-30 minutes
- Processing: ~5-60 minutes
- In Review: ~24-48 hours
- Total: ~1-3 days typically

**What to Do While Waiting:**
- Prepare support documentation
- Monitor App Store Connect
- Prepare for user questions
- Plan next version features
- Update marketing materials

---

## ⚠️ Common Issues & Solutions

**Build Upload Fails:**
- Check provisioning profile validity
- Verify bundle identifier matches
- Ensure certificates are current
- Try "Automatically manage signing"

**Missing Compliance:**
- Export Compliance may be required
- Answer encryption questions accurately
- Most apps select "No" for encryption

**Metadata Rejected:**
- Ensure privacy policy is accessible
- Verify all required fields completed
- Check screenshots are appropriate
- Review app description for clarity

**Account Deletion Issues:**
- Test deletion thoroughly before submission
- Provide clear instructions to reviewers
- Include in demo account notes
- Ensure support email is monitored

---

**Last Updated:** December 7, 2025
**Version:** 1.1.0+2
**Status:** Ready for Submission ✅
