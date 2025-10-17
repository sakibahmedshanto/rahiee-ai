# FCM Push Notification Implementation

## Overview
This document describes the implementation of Firebase Cloud Messaging (FCM) for push notifications in the Rahiee AI app. When users sign in, their device tokens are automatically saved to the database for push notification delivery.

## Implementation Details

### 1. Database Setup
- **Table**: `my_users`
- **Field**: `user_device_token` (TEXT, nullable)
- **Purpose**: Stores FCM device tokens for each user

The `my_users` table was created with the following structure:
```sql
CREATE TABLE IF NOT EXISTS my_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id VARCHAR(50) UNIQUE NOT NULL,
    username VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    user_img TEXT,
    user_device_token TEXT, -- For FCM push notifications
    full_name VARCHAR(255) NOT NULL,
    -- ... other fields
);
```

### 2. Dependencies Added
- `firebase_core: ^3.15.2`
- `firebase_messaging: ^15.2.10`

### 3. FCM Service (`lib/services/fcm_service.dart`)
The `FCMService` handles all FCM-related functionality:

#### Key Features:
- **Device Token Retrieval**: Automatically gets FCM device token on app initialization
- **Permission Handling**: Requests notification permissions from users
- **Token Refresh**: Listens for token refresh events and updates database
- **Message Handling**: Handles foreground, background, and notification tap events
- **Database Integration**: Saves device tokens to user profiles

#### Key Methods:
- `initializeFCM()`: Initializes FCM and requests permissions
- `saveDeviceTokenForUser(String userId)`: Saves device token for specific user
- `subscribeToTopic(String topic)`: Subscribe to notification topics
- `unsubscribeFromTopic(String topic)`: Unsubscribe from topics

### 4. Sign-In Integration

#### Email Sign-In (`lib/screens/auth_ui/sign_in_screen.dart`)
When a user successfully signs in with email/password:
1. User authentication is verified
2. User profile is loaded/created
3. Device token is automatically saved to database
4. User proceeds to main app

```dart
// Save device token for push notifications
try {
  await fcmService.saveDeviceTokenForUser(authResponse.user!.id);
} catch (e) {
  // Don't block sign-in if device token saving fails
  print('Failed to save device token: $e');
}
```

#### Google Sign-In (`lib/controllers/auth_controller/google_sign_in_controller.dart`)
When a user signs in with Google:
1. Google OAuth authentication
2. User profile creation/update
3. Device token is automatically saved to database
4. User proceeds to main app

### 5. App Initialization (`lib/main.dart`)
FCM service is initialized when the app starts:
```dart
// Initialize Firebase
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);

// Initialize services
Get.put(FCMService());
```

### 6. User Model Integration
The `UserModel` class already includes the `userDeviceToken` field:
```dart
class UserModel {
  final String? userDeviceToken; // Optional for push notifications
  // ... other fields
}
```

## Usage Flow

### For New Users:
1. User signs up/signs in
2. FCM service requests notification permissions
3. Device token is generated
4. Token is saved to `my_users.user_device_token`
5. User can receive push notifications

### For Existing Users:
1. User signs in
2. FCM service checks for existing token
3. If token changed, updates database
4. User continues to receive notifications

### Token Refresh:
- FCM automatically refreshes tokens periodically
- Service listens for refresh events
- Database is automatically updated with new token

## Error Handling
- Device token saving failures don't block user sign-in
- Errors are logged for debugging
- Graceful fallback if FCM initialization fails

## Security Considerations
- Device tokens are stored securely in Supabase
- Row Level Security (RLS) policies protect user data
- Only authenticated users can update their own device tokens

## Future Enhancements
- Topic-based notifications (department, role-specific)
- Rich notification content
- Notification history tracking
- User notification preferences
- Scheduled notifications

## Testing
To test the implementation:
1. Sign in with email or Google
2. Check database: `SELECT user_device_token FROM my_users WHERE id = 'user_id'`
3. Verify token is saved and not null
4. Test notification delivery using Firebase Console

## Troubleshooting
- Check Firebase project configuration
- Verify notification permissions are granted
- Check device token is being generated
- Ensure database connection is working
- Review error logs for FCM initialization issues
