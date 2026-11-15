# Email Rate Limit Fix — Supabase Auth Configuration

## Root Cause

The "Email Rate Limit Exceeded" error occurs because:

1. **Email confirmation is enabled by default** in Supabase Auth. Every new signup triggers a confirmation email, which counts against Supabase's free-tier email sending limits.
2. **No custom SMTP is configured.** Supabase's default email service has strict rate limits (approximately 50-100 emails per hour on free tier).
3. **The `resendConfirmationEmail` method was incorrectly using `resetPasswordForEmail`** (password reset flow) instead of properly handling confirmation resends.

## Required Changes (Supabase Dashboard)

These changes MUST be made in the Supabase Dashboard — they cannot be done from the Flutter app:

### Step 1: Disable Email Confirmation (Critical)

This is the most important fix. It stops confirmation emails from being sent on every signup, which eliminates the rate limit for new registrations.

1. Go to your Supabase project dashboard
2. Navigate to **Authentication → Settings**
3. Find **"Enable email confirmations"** and set it to **OFF**
4. Click **Save**

With confirmation disabled:
- Users can sign up and sign in immediately without clicking a confirmation link
- No confirmation emails are sent on signup (no rate limit consumption)
- Users can register with multiple different email addresses freely

### Step 2: Configure Custom SMTP (For Password Reset Emails)

If you need password reset emails to work reliably, configure custom SMTP:

1. Go to **Authentication → Email Templates → SMTP Settings**
2. Enter your SMTP provider details:
   - **Host:** e.g. `smtp.sendgrid.net`, `smtp.mailgun.org`, `smtp.gmail.com`
   - **Port:** `587` (TLS) or `465` (SSL)
   - **Username:** your SMTP username
   - **Password:** your SMTP password / API key
   - **Sender email:** a verified sender address (e.g. `noreply@yourdomain.com`)
   - **Sender name:** `JP Auction Arena`
3. Click **Save**

Recommended SMTP providers (free tiers available):
- **SendGrid:** 100 emails/day free
- **Mailgun:** 5,000 emails/month free
- **AWS SES:** 62,000 emails/month free
- **Brevo (Sendinblue):** 300 emails/day free

### Step 3: Configure Flutter Environment Variables (Optional)

If you want to store SMTP settings in the Flutter app for reference or future server-side use, pass them via `--dart-define`:

```bash
flutter run --dart-define=SUPABASE_URL=YOUR_URL \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY \
  --dart-define=SMTP_HOST=smtp.sendgrid.net \
  --dart-define=SMTP_PORT=587 \
  --dart-define=SMTP_USER=your_smtp_user \
  --dart-define=SMTP_PASS=your_smtp_pass \
  --dart-define=SMTP_FROM=noreply@yourdomain.com \
  --dart-define=SMTP_FROM_NAME="JP Auction Arena"
```

These values are read by `SupabaseConfig` and exposed as `smtpConfigured`, `smtpHost`, etc. They are not used by the client-side Flutter code for sending emails (Supabase handles that server-side), but they document your SMTP setup.

## How the Code Fixes Work

### Rate Limiter Cooldown (`EmailRateLimiter`)

- Located in `lib/data/repositories/auth_provider.dart`
- Tracks when Supabase returns a rate-limit error
- Enforces a 10-minute cooldown before allowing another email operation
- Shows a countdown in the UI so users know exactly how long to wait

### Error Handling

- `lib/features/login/login_screen.dart` — `_mapAuthError()` detects rate-limit messages and shows: *"Too many sign-up attempts. Please wait X seconds and try again."*
- The "Resend" button on the confirmation snackbar also checks the rate limiter before attempting to resend

### Email Confirmation Handling

- `lib/core/supabase/supabase_auth_service.dart` — `signUp()` creates the `profiles` row regardless of confirmation status
- If email confirmation is required (still enabled in Supabase), users see a snackbar telling them to check their email
- If confirmation is disabled (recommended), users are auto-signed in and redirected to the dashboard

## Testing the Complete Flow

### Test 1: New User Signup

1. Open the app and go to the Sign Up tab
2. Enter a new email address, password, name, and optional org/phone
3. Tap "Create Account"
4. **Expected:** Account created successfully → redirected to Dashboard (if confirmation disabled) OR shown confirmation message (if confirmation enabled)
5. **Verify:** The new user appears in Supabase Dashboard → Authentication → Users

### Test 2: Multiple Different Email Addresses

1. Sign up with `user1@example.com`
2. Sign out
3. Sign up with `user2@example.com`
4. Sign out
5. Sign up with `user3@example.com`
6. **Expected:** All three signups succeed without rate-limit errors (confirmation disabled)

### Test 3: Login

1. After signing up, sign out
2. Go to the Sign In tab
3. Enter the same email and password
4. Tap "Sign In"
5. **Expected:** Successfully signed in → redirected to Dashboard

### Test 4: Rate Limit Behavior (if confirmation still enabled)

1. Rapidly attempt 5-6 signups with different emails in quick succession
2. **Expected:** After hitting the limit, see: *"Too many sign-up attempts. Please wait X seconds and try again."*
3. Wait for the countdown to reach 0
4. **Expected:** Can sign up again without error

## Verification Checklist

- [ ] Email confirmation disabled in Supabase Dashboard
- [ ] Custom SMTP configured (optional but recommended for password resets)
- [ ] New user can sign up with any email address
- [ ] New user can sign in immediately after signup
- [ ] Multiple email addresses can be used without rate limits
- [ ] Password reset email works (if SMTP configured)
- [ ] Rate limit cooldown UI shows correctly when limit is hit

## Files Modified

| File | Change |
|------|--------|
| `lib/core/supabase/supabase_config.dart` | Added SMTP configuration fields (`smtpHost`, `smtpPort`, `smtpUser`, `smtpPass`, `smtpFrom`, `smtpFromName`, `smtpConfigured`) |
| `lib/core/supabase/supabase_auth_service.dart` | Added `isConfirmationRequired()`, clarified comment documentation, kept `resendConfirmationEmail` using `resetPasswordForEmail` (Supabase client SDK limitation) |
| `lib/data/repositories/auth_provider.dart` | Added `EmailRateLimiter` singleton with 10-minute cooldown, rate-limit checks in `signUp()`, `resetPassword()`, `resendConfirmationEmail()` |
| `lib/features/login/login_screen.dart` | Added `dart:async` import, `Timer` for cooldown countdown, `_getCooldownSeconds()`, `_isRateLimited`, `_startCooldownTimer()`, cooldown warning UI in sign-up card, rate-limit error message with remaining seconds |
