# Web Testing Setup (Chrome)

## ✅ What You've Done
- Added callback URL to Google Cloud Console: `https://qxdgkioixstyigbvohmc.supabase.co/auth/v1/callback`
- Created Web Application OAuth client

## 🎯 Next Steps for Web Testing

### 1. Verify Google Cloud Console Settings

Make sure in your Google Cloud Console OAuth client:

**Authorized JavaScript origins:**
```
http://localhost:3000
http://localhost
https://qxdgkioixstyigbvohmc.supabase.co
```

**Authorized redirect URIs:**
```
https://qxdgkioixstyigbvohmc.supabase.co/auth/v1/callback
http://localhost:3000
```

### 2. Configure Supabase Site URL

1. Go to Supabase Dashboard → **Authentication** → **URL Configuration**
2. Set **Site URL** to: `http://localhost:3000` (for local testing)
3. Add **Redirect URLs**:
   - `http://localhost:3000`
   - `http://localhost:3000/**` (wildcard for all routes)

### 3. Run Your Flutter Web App

```bash
# Clean and get dependencies
flutter clean
flutter pub get

# Run on Chrome
flutter run -d chrome --web-port 3000
```

**Important:** Use port 3000 to match the authorized origins!

### 4. Test the Flow

1. App should open in Chrome at `http://localhost:3000`
2. Navigate to the Login screen
3. Click **Continue with Google**
4. You'll be redirected to Google's login page
5. After login, you'll be redirected back to your app
6. User profile will be auto-created in Supabase

## 🔍 Troubleshooting

### "Error 400: redirect_uri_mismatch"
**Solution:** Add `http://localhost:3000` to both:
- Authorized JavaScript origins
- Authorized redirect URIs

### "Access blocked: This app's request is invalid"
**Solution:** 
- Make sure OAuth consent screen is configured
- Add your email as a test user (if app is in testing mode)
- Verify Client ID and Secret are correct in Supabase

### OAuth popup blocked
**Solution:**
- Allow popups for localhost in Chrome
- Or check browser console for errors

### User not created in database
**Solution:**
- Check Supabase logs (Dashboard → Logs → Auth)
- Verify RLS policies allow inserts to `users` table
- Check browser console for JavaScript errors

## 📱 For Mobile Testing Later

When you're ready to test on mobile:
1. Follow the deep linking setup in `SOCIAL_AUTH_SETUP.md`
2. Use the mobile redirect URI: `io.supabase.shiftsphere://login-callback/`
3. Create separate OAuth clients for Android/iOS in Google Cloud Console

## 🎉 Success Indicators

You'll know it's working when:
1. ✅ Google login page opens in a new tab/popup
2. ✅ After login, you're redirected back to your app
3. ✅ You see a success message
4. ✅ User appears in Supabase Dashboard → Authentication → Users
5. ✅ User profile created in `public.users` table

## Current Configuration Summary

```
Supabase Project: qxdgkioixstyigbvohmc
Callback URL: https://qxdgkioixstyigbvohmc.supabase.co/auth/v1/callback
Testing Platform: Web (Chrome)
Local Port: 3000
```
