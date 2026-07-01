// This file is gitignored — it holds real credentials and never gets committed.
// Template with setup instructions: api_keys.example.dart
//
// The previous values committed here were exposed publicly on GitHub
// (commit a82abb42) and have been rotated. Fill in the NEW values below
// after generating them in each provider's console.
class ApiKeys {
  static const String googleMaps = 'YOUR_GOOGLE_MAPS_API_KEY';

  static bool get isConfigured => googleMaps != 'YOUR_GOOGLE_MAPS_API_KEY';

  static const bool mpesaIsProduction = false; // → change to true when ready

  static const String mpesaConsumerKey    = 'YOUR_MPESA_CONSUMER_KEY';
  static const String mpesaConsumerSecret = 'YOUR_MPESA_CONSUMER_SECRET';

  static const String mpesaBusinessShortCode = '174379';
  static const String mpesaPasskey =
      'bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919';

  static const String mpesaCallbackUrl =
      'https://example.com/taftaf/mpesa-callback';

  static const bool isMpesaConfigured = true;

  static const String emailjsServiceId  = 'YOUR_EMAILJS_SERVICE_ID';
  static const String emailjsTemplateId = 'YOUR_EMAILJS_TEMPLATE_ID';
  static const String emailjsPublicKey  = 'YOUR_EMAILJS_PUBLIC_KEY';
  static const String emailjsPrivateKey = 'YOUR_EMAILJS_PRIVATE_KEY';

  static const int zegoAppId = 0;
  static const String zegoAppSign = '';
}
