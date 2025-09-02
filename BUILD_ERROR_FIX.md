# Flutter setState During Build Fix

## Problem
```
FlutterError (setState() or markNeedsBuild() called during build.
This Overlay widget cannot be marked as needing to build because the framework is already in the process of building widgets.
The widget which was currently being built when the offending call was made was: LandingScreen
```

## Root Cause
The error was caused by calling navigation (`Get.offNamed()`) during the `build()` method of `LandingScreen`. Specifically:

1. `LandingScreen.build()` method was calling `controller.initializeWithUser(widget.userModel)`
2. `initializeWithUser()` method was checking if user is admin and calling `Get.offNamed('/admin')` 
3. Navigation during build phase triggers setState/markNeedsBuild on overlay widgets
4. This violates Flutter's rule that widgets cannot be marked dirty during build

## Solution

### Before (Problematic Code)
```dart
// In LandingScreen
@override
Widget build(BuildContext context) {
  final LandingController controller = Get.put(LandingController());
  controller.initializeWithUser(widget.userModel); // <- Navigation during build
  
  return Scaffold(
    // ...
  );
}

// In LandingController
void initializeWithUser(UserModel user) {
  userModel = user;
  
  if (userModel.isAdmin) {
    Get.offNamed('/admin', arguments: userModel); // <- setState during build
  }
}
```

### After (Fixed Code)
```dart
// In LandingScreen
class _LandingScreenState extends State<LandingScreen> {
  final RxInt _selectedIndex = 0.obs;
  late final LandingController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(LandingController());
    controller.initializeWithUser(widget.userModel); // <- Safe in initState
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... no navigation calls during build
    );
  }
}

// In LandingController
void initializeWithUser(UserModel user) {
  userModel = user;
  
  if (userModel.isAdmin) {
    Get.offNamed('/admin', arguments: userModel); // <- Safe from initState
  }
}
```

## Key Changes

1. **Moved Controller Initialization**: Moved `Get.put(LandingController())` from `build()` to `initState()`
2. **Moved User Initialization**: Moved `controller.initializeWithUser()` call from `build()` to `initState()`
3. **Safe Navigation**: Navigation now happens from `initState()` which is safe for state changes

## Why This Works

- **initState()**: Called once when widget is first created, before first build
- **build()**: Called every time widget needs to rebuild
- **Navigation Safety**: State changes and navigation are safe during `initState()` but not during `build()`

## Alternative Solutions Considered

1. **PostFrameCallback**: Could use `WidgetsBinding.instance.addPostFrameCallback()` to defer navigation
2. **Future.microtask**: Could defer navigation to next event loop
3. **Separate Navigation Method**: Could separate initialization from navigation

The chosen solution is cleanest as it follows Flutter best practices by using `initState()` for one-time initialization.

## Prevention Guidelines

- Never call navigation methods directly in `build()` methods
- Never call `setState()` or state-changing methods in `build()` methods  
- Use `initState()`, `didChangeDependencies()`, or post-frame callbacks for navigation
- Use `WidgetsBinding.instance.addPostFrameCallback()` if navigation must be conditional on build completion

## Testing

After the fix:
- ✅ LandingScreen builds without errors
- ✅ Admin users are properly redirected to admin screen
- ✅ Regular users stay on landing screen
- ✅ No setState during build exceptions
- ✅ Navigation works as expected
