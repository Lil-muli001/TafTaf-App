// Copy this file to api_keys.dart and fill in your real credentials.
// api_keys.dart is gitignored — it will never be committed.
class ApiKeys {
  // ── Google Maps / Places ──────────────────────────────────────────────────
  // Enable in Google Cloud Console:
  //   • Maps SDK for Android / iOS
  //   • Places API (New)  •  Geocoding API
  // Also set GOOGLE_MAPS_API_KEY in android/secrets.properties and
  // ios/Flutter/Secrets.xcconfig (see the .example files next to each).
  // ─────────────────────────────────────────────────────────────────────────
  static const String googleMaps = 'YOUR_GOOGLE_MAPS_API_KEY';

  static bool get isConfigured => googleMaps != 'YOUR_GOOGLE_MAPS_API_KEY';

  // ── Safaricom Daraja (M-Pesa) ─────────────────────────────────────────────
  //
  // SANDBOX (testing — use these while developing):
  //   Consumer Key & Secret → developer.safaricom.co.ke → your app → Keys
  //   ShortCode: 174379  (Safaricom public test paybill)
  //   Passkey: the long string below  (Safaricom public sandbox passkey)
  //   CallbackUrl: any reachable HTTPS URL (e.g. a Supabase Edge Function)
  //
  // PRODUCTION (going live):
  //   1. Set mpesaIsProduction = true
  //   2. Replace Consumer Key/Secret with your PRODUCTION app credentials
  //   3. Replace ShortCode with your actual Paybill or Till number
  //   4. Replace Passkey with the one from M-Pesa → Paybill/Till settings
  //   5. Set CallbackUrl to your live backend endpoint
  // ─────────────────────────────────────────────────────────────────────────

  // Set to true once you have production credentials and a live callback URL.
  // ⚠️  REPLACE ALL VALUES BELOW BEFORE SETTING THIS TO true  ⚠️
  static const bool mpesaIsProduction = false; // → change to true when ready

  // ── Credentials (from developer.safaricom.co.ke → your sandbox/live app → Keys) ──
  // SANDBOX: developer.safaricom.co.ke → Apps → your sandbox app → Keys tab
  // PRODUCTION: replace with your live app's Consumer Key and Secret
  static const String mpesaConsumerKey    = 'YOUR_MPESA_CONSUMER_KEY';
  static const String mpesaConsumerSecret = 'YOUR_MPESA_CONSUMER_SECRET';

  // ── Paybill / Till details ─────────────────────────────────────────────────
  // SANDBOX: 174379 is Safaricom's public test paybill — works for all sandbox apps.
  // PRODUCTION: replace with your actual Paybill or Till number.
  static const String mpesaBusinessShortCode = '174379';
  // SANDBOX: public sandbox passkey shared by all Daraja sandbox apps — do not change for testing.
  // PRODUCTION: replace with the Passkey from M-Pesa portal → your Paybill/Till settings.
  static const String mpesaPasskey =
      'bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919';

  // ── Callback URL ──────────────────────────────────────────────────────────
  // Must be a valid HTTPS URL (Daraja validates the format at STK push time).
  // The app polls Daraja directly for status, so this URL only needs to be
  // reachable in production. For sandbox, the placeholder below is sufficient.
  static const String mpesaCallbackUrl =
      'https://example.com/taftaf/mpesa-callback';

  static const bool isMpesaConfigured = true;

  // ── EmailJS (password reset OTP emails) ──────────────────────────────────
  //
  // Setup (free — 200 emails/month):
  //   1. Create account at emailjs.com
  //   2. Add Email Service (e.g. Gmail): Email Services → Add New Service
  //   3. Create Template:  Email Templates → Create New Template
  //        Subject : TafTaf — Password Reset Code
  //        Body    : Your TafTaf reset code is: {{otp_code}}
  //                  It expires in 15 minutes. If you didn't request this, ignore it.
  //        To Email: {{to_email}}
  //   4. Copy Service ID, Template ID, and Public Key (Account → General) below.
  // ─────────────────────────────────────────────────────────────────────────
  static const String emailjsServiceId  = 'YOUR_EMAILJS_SERVICE_ID';
  static const String emailjsTemplateId = 'YOUR_EMAILJS_TEMPLATE_ID';
  static const String emailjsPublicKey  = 'YOUR_EMAILJS_PUBLIC_KEY';
  // Private key → emailjs.com → Account → General → Private Key
  // Required for requests from mobile apps (bypasses the allowed-origins check).
  static const String emailjsPrivateKey = 'YOUR_EMAILJS_PRIVATE_KEY';

  // ── ZegoCloud (In-App Voice Calling) ─────────────────────────────────────
  //
  // Get your FREE credentials at console.zegocloud.com:
  //   1. Sign up → Create a Project → choose "Voice Call" as the product
  //   2. Copy the AppID (integer) and AppSign (64-char hex string) below
  //   3. Free tier: 10,000 call minutes/month
  //
  // Leave both as 0 / '' until you have credentials — the call service
  // will throw a readable error before attempting to join any call.
  // ─────────────────────────────────────────────────────────────────────────
  static const int zegoAppId = 0;       // REPLACE with your AppID (int)
  static const String zegoAppSign = ''; // REPLACE with your AppSign (String)
}
