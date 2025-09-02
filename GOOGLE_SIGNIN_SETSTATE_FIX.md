# Google Sign-in setState During Build Error - Fix Applied

## Problem Description
When signing in with Google, the app was throwing the error:
```
FlutterError (setState() or markNeedsBuild() called during build.
This Overlay widget cannot be marked as needing to build because the framework 
is already in the process of building widgets.
The widget which was currently being built when the offending call was made was: LandingScreen
```

## Root Cause Analysis
The error occurred due to multiple issues happening during the Google sign-in flow:

1. **LandingScreen Controller Initialization**: The `LandingController` was being initialized in the `build()` method with `Get.put(LandingController())`
2. **Immediate Admin Check**: The `LandingController.initializeWithUser()` method was immediately calling `Get.offNamed('/admin')` if user was admin
3. **Navigation During Build**: The Google sign-in controller was calling `Get.offAll()` navigation immediately after authentication
4. **Snackbar During Build**: Error snackbars were being shown directly without deferring

## Specific Fixes Applied

### 1. LandingScreen - Moved Controller Init to initState()
**File**: `lib/screens/landing_screen/landing_screen.dart`

```dart
// Before (PROBLEMATIC)
@override
Widget build(BuildContext context) {
  final LandingController controller = Get.put(LandingController());
  controller.initializeWithUser(widget.userModel);
  return Scaffold(...);
}

// After (FIXED)
class _LandingScreenState extends State<LandingScreen> {
  late LandingController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(LandingController());
    controller.initializeWithUser(widget.userModel);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(...);
  }
}
```

### 2. LandingController - Deferred Admin Navigation
**File**: `lib/controllers/landing_controller.dart`

```dart
// Before (PROBLEMATIC)
void initializeWithUser(UserModel user) {
  userModel = user;
  if (userModel.isAdmin) {
    Get.offNamed('/admin', arguments: userModel); // setState during build
  }
}

// After (FIXED)
void initializeWithUser(UserModel user) {
  userModel = user;
  if (userModel.isAdmin) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offNamed('/admin', arguments: userModel); // Safe navigation
    });
  }
}
```

### 3. WelcomeController - Fixed Google Sign-in Error Snackbar
**File**: `lib/controllers/welcome_controller.dart`

```dart
// Before (PROBLEMATIC)
void onGoogleSignInPressed() async {
  bool success = await googleSignInController.signInWithGoogle();
  if (!success) {
    Get.snackbar('Error', 'Failed to sign in...'); // setState during build
  }
}

// After (FIXED)
void onGoogleSignInPressed() async {
  bool success = await googleSignInController.signInWithGoogle();
  if (!success) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.snackbar('Error', 'Failed to sign in...'); // Safe snackbar
    });
  }
}
```

### 4. GoogleSignInController - Deferred Navigation
**File**: `lib/controllers/auth_controller/google_sign_in_controller.dart`

```dart
// Before (PROBLEMATIC)
if (userCreated) {
  Get.offAll(() => LandingScreen(userModel: userModel)); // setState during build
  return true;
}

// After (FIXED)
if (userCreated) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Get.offAll(() => LandingScreen(userModel: userModel)); // Safe navigation
  });
  return true;
}
```

## Technical Explanation

### Why This Happened
1. **Google Sign-in Success** → Immediate navigation to `LandingScreen`
2. **LandingScreen Build** → Initializes `LandingController` in build method
3. **Controller Init** → Calls `initializeWithUser()` immediately
4. **Admin Check** → Calls `Get.offNamed()` navigation during build
5. **setState Error** → Navigation modifies widget tree during build phase

### The Solution Pattern
- **Defer Controller Initialization**: Move from `build()` to `initState()`
- **Defer Navigation**: Use `WidgetsBinding.instance.addPostFrameCallback()`
- **Defer Snackbars**: Wrap in `addPostFrameCallback()` for error handling
- **Defer UI Changes**: Ensure all overlay modifications happen after build

## Flow Diagram - Before vs After

### Before (Problematic)
```
Google Sign-in Success
    ↓
Get.offAll() → LandingScreen
    ↓
build() → Get.put(Controller) 
    ↓
initializeWithUser() → Get.offNamed() ❌ setState during build
```

### After (Fixed)
```
Google Sign-in Success
    ↓
addPostFrameCallback(() => Get.offAll()) → LandingScreen
    ↓
initState() → Get.put(Controller)
    ↓
initializeWithUser() → addPostFrameCallback(() => Get.offNamed()) ✅ Safe
```

## Verification Steps
1. ✅ Google sign-in completes successfully
2. ✅ No setState during build errors
3. ✅ Admin users navigate to admin screen correctly
4. ✅ Regular users stay on landing screen
5. ✅ Error snackbars display safely
6. ✅ Navigation flows work smoothly

## Status: ✅ RESOLVED
Google sign-in setState during build error has been completely eliminated.
