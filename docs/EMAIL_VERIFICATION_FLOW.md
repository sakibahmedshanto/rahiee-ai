# Email Verification Flow - Rahiee AI

## Overview
This document explains the new email verification flow implemented in the Rahiee AI app.

## Flow Description

### 1. **User Signup Process**
- User fills out signup form (name, email, phone, city, password)
- App calls `SignUpController.signUpMethod()`
- Supabase creates auth user and sends verification email
- **No user profile is created in `my_users` table yet**
- User is redirected to sign-in screen with success message
- User must check email and click verification link

### 2. **Email Verification**
- User receives email with verification link
- User clicks the link to verify their email
- Supabase marks the email as confirmed (`email_confirmed_at` is set)

### 3. **First Login After Verification**
- User attempts to sign in with email/password
- App calls `SignInController.signInMethod()`
- Controller checks if email is verified (`emailConfirmedAt != null`)
- If verified:
  - Checks if user profile exists in `my_users` table
  - If no profile exists, creates one automatically with auth metadata
  - Returns the UserModel for successful login
- If not verified:
  - Shows "Email Verification Required" message
  - Signs out the user

### 4. **Subsequent Logins**
- User signs in normally
- Controller loads existing profile from `my_users` table
- User proceeds to main app

## Code Changes Made

### SignUpController
```dart
// Only creates auth user, sends verification email
// Does NOT create profile in my_users table
Future<AuthResponse?> signUpMethod(...)
```

### SignInController  
```dart
// Checks email verification status
// Creates profile in my_users table on first verified login
Future<UserModel?> signInMethod(...)
```

### Database Policies
```sql
-- Only verified users can create profiles
CREATE POLICY "Verified users can insert own profile" ON public.my_users
    FOR INSERT WITH CHECK (
        auth.uid() = id 
        AND auth.role() = 'authenticated'
        AND auth.email_confirmed_at() IS NOT NULL
    );
```

## Benefits

1. **Enhanced Security**: Only verified email addresses can access the app
2. **Clean Database**: No unverified user records in `my_users` table
3. **Better UX**: Clear messaging about verification requirements
4. **Compliance**: Follows email verification best practices

## Configuration Requirements

### Supabase Dashboard Settings

1. **SMTP Configuration**
   - Go to Authentication > Settings > SMTP Settings
   - Configure your email provider (Gmail, SendGrid, etc.)

2. **Email Confirmations**
   - Go to Authentication > Settings
   - Enable "Email confirmations"
   - Optionally enable "Double confirm email changes"

3. **Email Templates**
   - Go to Authentication > Templates
   - Customize "Confirm signup" email template
   - Update subject line and content as needed

### SQL Scripts to Run

1. **Update RLS Policies**: Run `email_verification_setup.sql`
2. **Fix Signup Issues**: Run `fix_signup_rls_policy.sql` (if needed)
3. **Create Users Table**: Run `my_users_table_setup.sql` (if not done)

## Testing the Flow

1. **Test Signup**:
   - Register with valid email
   - Verify you receive confirmation email
   - Check that no profile is created in `my_users` table yet

2. **Test Verification**:
   - Click email verification link
   - Verify email is marked as confirmed in Supabase auth

3. **Test First Login**:
   - Sign in with verified credentials
   - Verify profile is created in `my_users` table
   - Verify successful navigation to main app

4. **Test Unverified Login**:
   - Register with new email but don't verify
   - Try to sign in immediately
   - Verify "Email Verification Required" message appears

## Error Handling

- **Rate Limiting**: App handles Supabase rate limits for email sending
- **Verification Checks**: Clear messages when email not verified
- **Profile Creation Failures**: Proper error handling and user feedback
- **Network Issues**: Graceful handling of connection problems

## User Messages

- **Signup Success**: "Account created successfully! Please check your email and click the verification link before signing in."
- **Login Without Verification**: "Please check your email and click the verification link before signing in."
- **First Login Success**: "Login successful!" (profile created automatically)
- **Subsequent Logins**: "Login successful!" (existing profile loaded)

This flow ensures that only users with verified email addresses can access the application and have their data stored in the database.
