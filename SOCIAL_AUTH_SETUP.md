# Social Authentication Setup Guide

This guide explains how to configure Google and Facebook OAuth for ShiftSphere.

## Architecture

The social authentication is organized into modular components:

```
lib/
├── services/
│   └── social_auth_service.dart          # OAuth logic & Supabase integration
├── views/
│   ├── widgets/
│   │   └── social_button.dart            # Reusable button component
│   └── auth/
│       └── widgets/
│           └── social_login_section.dart # UI container for social buttons
```

## Configuration Steps

### 1. Supabase Dashboard Setup

#### Google OAuth

1. Go to your Supabase project dashboard
2. Navigate to **Authentication** > **Providers**
3. Enable **Google**
4. You'll need to create a Google Cloud Project:
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new project or select existing
   - Enable **Google+ API**
   - Go to **Credentials** > **Create Credentials** > **OAuth 2.0 Client ID**
   - Application type: **Web application**
   - Authorized redirect URIs: Add your Supabase callback URL
     ```
     https://<your-project-ref>.supabase.co/auth/v1/callback
     ```
5. Copy the **Client ID** and **Client Secret**
6. Paste them into Supabase Google provider settings
7. Save

#### Facebook OAuth

1. In Supabase dashboard: **Authentication** > **Providers**
2. Enable **Facebook**
3. Create a Facebook App:
   - Go to [Facebook Developers](https://developers.facebook.com/)
   - Create a new app (Consumer type)
   - Add **Facebook Login** product
   - Go to **Settings** > **Basic**
   - Copy **App ID** and **App Secret**
4. Configure Facebook Login:
   - Go to **Facebook Login** > **Settings**
   - Add OAuth Redirect URI:
     ```
     https://<your-project-ref>.supabase.co/auth/v1/callback
     ```
5. Paste App ID and Secret into Supabase
6. Save

### 2. Deep Linking Setup (Required for Mobile)

For the OAuth flow to work in your Flutter app, you need to configure deep linking.

#### Android (`android/app/src/main/AndroidManifest.xml`)

Add inside `<activity>` tag:

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="io.supabase.shiftsphere"
        android:host="login-callback" />
</intent-filter>
```

#### iOS (`ios/Runner/Info.plist`)

Add before `</dict>`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>io.supabase.shiftsphere</string>
        </array>
    </dict>
</array>
```

### 3. Handle OAuth Callback in App

The `SocialAuthService` already handles the callback logic. When the user returns from Google/Facebook, Supabase will:

1. Authenticate the user
2. Create a session
3. Trigger the deep link callback
4. `handleOAuthCallback()` will create the user profile if needed

### 4. Testing

1. **Hot Restart** your app (not just hot reload)
2. Go to the Login screen
3. Tap "Continue with Google" or "Continue with Facebook"
4. You should be redirected to the OAuth provider
5. After authentication, you'll be redirected back to the app

## Required Credentials Summary

### Google
- **Client ID**: From Google Cloud Console
- **Client Secret**: From Google Cloud Console
- **Redirect URI**: `https://<your-project-ref>.supabase.co/auth/v1/callback`

### Facebook
- **App ID**: From Facebook Developers
- **App Secret**: From Facebook Developers
- **Redirect URI**: `https://<your-project-ref>.supabase.co/auth/v1/callback`

## Troubleshooting

### "OAuth provider not configured"
- Make sure you enabled the provider in Supabase dashboard
- Verify Client ID/Secret are correctly entered

### "Redirect URI mismatch"
- Check that the redirect URI in Google/Facebook matches exactly with Supabase
- Make sure there are no trailing slashes

### Deep link not working
- Verify AndroidManifest.xml and Info.plist are configured correctly
- Do a **full rebuild** of the app (not just hot reload)
- Check that the scheme matches: `io.supabase.shiftsphere`

### User not created in database
- Check Supabase logs for errors
- Verify RLS policies allow inserts to `users` table
- The `handleOAuthCallback()` method should auto-create the user

## Security Notes

- Never commit OAuth secrets to version control
- Use environment variables for production
- Enable email verification in Supabase for additional security
- Consider adding role selection after first OAuth login
