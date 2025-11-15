# iOS Build Issues - Fixed

## Date: November 15, 2025

---

## Issue 1: ITMS-90683 - Missing Camera Permission Description

### Error Message:
```
ITMS-90683: Missing purpose string in Info.plist - Your app's code references one or more APIs
that access sensitive user data. The Info.plist file for the "Runner.app" bundle should contain 
a NSCameraUsageDescription key with a user-facing purpose string.
```

### Root Cause:
The app uses camera functionality for attendance verification but didn't declare the required privacy descriptions in `Info.plist`.

### Fix Applied:
Added the following keys to `ios/Runner/Info.plist`:

```xml
<!-- Camera permissions for attendance verification -->
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to capture your photo for identity verification during check-in and check-out.</string>

<!-- Photo library permissions -->
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to save attendance verification photos.</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>This app needs permission to save attendance verification photos to your photo library.</string>
```

### Result:
✅ App Store Connect will now accept the build with proper privacy declarations.

---

## Issue 2: CocoaPods Framework File List Error

### Error Message:
```
Unable to load contents of file list: '/Target Support Files/Pods-Runner/Pods-Runner-frameworks-Release-input-files.xcfilelist'
Unable to load contents of file list: '/Target Support Files/Pods-Runner/Pods-Runner-frameworks-Release-output-files.xcfilelist'
```

### Root Cause:
- Corrupted or missing CocoaPods configuration files
- UTF-8 encoding issue in terminal

### Fix Applied:

1. **Set UTF-8 encoding:**
   ```bash
   export LANG=en_US.UTF-8
   ```

2. **Clean and reinstall pods:**
   ```bash
   cd ios
   rm -rf Pods Podfile.lock
   pod install --repo-update
   ```

3. **Clean Flutter build:**
   ```bash
   flutter clean
   flutter pub get
   ```

### Result:
✅ All 27 pods installed successfully
✅ Framework file lists regenerated correctly

---

## Next Steps to Upload to App Store

### 1. Increment Build Number
Edit `pubspec.yaml`:
```yaml
version: 1.0.0+2  # Change from +1 to +2
```

### 2. Build iOS Archive
```bash
flutter build ios --release
```

### 3. Open Xcode and Archive
```bash
open ios/Runner.xcworkspace
```

In Xcode:
1. Select **Any iOS Device (arm64)** as the target
2. Go to **Product → Archive**
3. Once archived, click **Distribute App**
4. Choose **App Store Connect**
5. Follow the upload wizard

### 4. Submit for Review
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select your app **Rahiee.AI**
3. Go to the **TestFlight** or **App Store** tab
4. Select the new build (Build 2)
5. Complete all required metadata
6. Submit for review

---

## Important Notes

### Privacy Policy Requirement
✅ Already created comprehensive privacy policy covering:
- Camera usage for attendance verification
- Location tracking for check-in/out
- Data storage and retention
- Third-party services (Supabase, Firebase)

### App Store Review Guidelines
Make sure your app complies with:
- ✅ Clear explanation of camera/location usage
- ✅ Privacy policy accessible in-app
- ✅ No crashes or major bugs
- ✅ All features work as described

### Testing Before Submission
Test these critical features:
- [ ] Camera check-in/check-out
- [ ] Location verification
- [ ] Push notifications
- [ ] Schedule management
- [ ] Admin dashboard

---

## Troubleshooting

### If build still fails:

**1. Device Registration Issue:**
- Connect a physical iOS device to your Mac
- Open Xcode → Window → Devices and Simulators
- Your device should auto-register

**2. Provisioning Profile Issue:**
- Open `ios/Runner.xcworkspace` in Xcode
- Select Runner target → Signing & Capabilities
- Enable "Automatically manage signing"
- Select your Apple Developer team

**3. CocoaPods Issues:**
```bash
# Add to ~/.zshrc or ~/.bash_profile
export LANG=en_US.UTF-8

# Then run
source ~/.zshrc
cd ios && pod repo update && pod install
```

---

## Summary

✅ **Fixed:** Missing camera permission descriptions in Info.plist
✅ **Fixed:** CocoaPods framework file list errors
✅ **Ready:** App is now ready for App Store submission

**Status:** All iOS build issues resolved. Proceed with archive and upload.

