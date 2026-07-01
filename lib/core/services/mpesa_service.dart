import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:taftaf/core/constants/api_keys.dart';

enum TransactionStatus {
  pending,
  success,
  failed,
  cancelled,
  insufficientBalance,
  unknown,
}

class StkPushResult {
  final bool isSuccess;
  final String? checkoutRequestId;
  final String? errorMessage;

  const StkPushResult._({
    required this.isSuccess,
    this.checkoutRequestId,
    this.errorMessage,
  });

  factory StkPushResult.success(String id) =>
      StkPushResult._(isSuccess: true, checkoutRequestId: id);

  factory StkPushResult.error(String msg) =>
      StkPushResult._(isSuccess: false, errorMessage: msg);
}

class MpesaService {
  static const _sandboxUrl    = 'https://sandbox.safaricom.co.ke';
  static const _productionUrl = 'https://api.safaricom.co.ke';
  static String get _baseUrl =>
      ApiKeys.mpesaIsProduction ? _productionUrl : _sandboxUrl;

  String? _cachedToken;
  DateTime? _tokenExpiry;
  String? _lastAuthError;

  // YYYYMMDDHHmmss timestamp required by Daraja
  String _timestamp() {
    final n = DateTime.now();
    return '${n.year}'
        '${n.month.toString().padLeft(2, '0')}'
        '${n.day.toString().padLeft(2, '0')}'
        '${n.hour.toString().padLeft(2, '0')}'
        '${n.minute.toString().padLeft(2, '0')}'
        '${n.second.toString().padLeft(2, '0')}';
  }

  // Normalise Kenyan number to 254XXXXXXXXX
  String formatPhone(String input) {
    final clean = input.replaceAll(RegExp(r'[\s\-+().]'), '');
    if (clean.startsWith('254')) return clean;
    if (clean.startsWith('0')) return '254${clean.substring(1)}';
    return '254$clean';
  }

  Future<String?> _getAccessToken() async {
    if (_cachedToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _cachedToken;
    }
    try {
      final creds = base64Encode(
        utf8.encode(
            '${ApiKeys.mpesaConsumerKey}:${ApiKeys.mpesaConsumerSecret}'),
      );
      final res = await http
          .get(
            Uri.parse(
                '$_baseUrl/oauth/v1/generate?grant_type=client_credentials'),
            headers: {'Authorization': 'Basic $creds'},
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _cachedToken = data['access_token'] as String;
        final exp =
            int.tryParse(data['expires_in'].toString()) ?? 3600;
        _tokenExpiry =
            DateTime.now().add(Duration(seconds: exp - 60));
        _lastAuthError = null;
        return _cachedToken;
      }
      // Surface the real Daraja rejection body so it appears in the UI.
      _lastAuthError = 'Daraja auth failed (${res.statusCode}): ${res.body}';
    } catch (e) {
      _lastAuthError = 'Network error reaching Daraja: $e';
    }
    return null;
  }

  Future<StkPushResult> initiateStkPush({
    required String phoneNumber,
    required int amount,
    required String accountReference,
    required String transactionDescription,
  }) async {
    // Guard: catch un-configured credentials before hitting the network.
    if (ApiKeys.mpesaConsumerKey.startsWith('REPLACE_') ||
        ApiKeys.mpesaConsumerSecret.startsWith('REPLACE_')) {
      return StkPushResult.error(
        'M-Pesa Consumer Key/Secret are not configured.\n'
        'Go to developer.safaricom.co.ke → your sandbox app → Keys '
        'and paste the values into api_keys.dart.',
      );
    }

    final token = await _getAccessToken();
    if (token == null) {
      return StkPushResult.error(
          _lastAuthError ?? 'Authentication failed. Check your Daraja API credentials.');
    }

    try {
      final ts = _timestamp();
      final rawPw =
          '${ApiKeys.mpesaBusinessShortCode}${ApiKeys.mpesaPasskey}$ts';
      final password = base64Encode(utf8.encode(rawPw));
      final phone = formatPhone(phoneNumber);

      final res = await http
          .post(
            Uri.parse('$_baseUrl/mpesa/stkpush/v1/processrequest'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'BusinessShortCode': ApiKeys.mpesaBusinessShortCode,
              'Password': password,
              'Timestamp': ts,
              'TransactionType': 'CustomerPayBillOnline',
              'Amount': amount,
              'PartyA': phone,
              'PartyB': ApiKeys.mpesaBusinessShortCode,
              'PhoneNumber': phone,
              'CallBackURL': ApiKeys.mpesaCallbackUrl,
              'AccountReference': accountReference,
              'TransactionDesc': transactionDescription,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['ResponseCode'] == '0') {
          return StkPushResult.success(
              data['CheckoutRequestID'] as String);
        }
        // Daraja returns ResponseDescription on logical errors; fall back to
        // errorMessage / errorCode for OAuth-layer or gateway errors.
        final desc = data['ResponseDescription']?.toString()
            ?? data['errorMessage']?.toString()
            ?? data['errorCode']?.toString()
            ?? 'STK push failed';
        return StkPushResult.error(desc);
      }
      // Non-200: surface the raw body so the error is diagnosable.
      return StkPushResult.error(
          'Request failed (${res.statusCode}): ${res.body}');
    } catch (e) {
      return StkPushResult.error('Network error: $e');
    }
  }

  Future<TransactionStatus> queryStatus(String checkoutRequestId) async {
    final token = await _getAccessToken();
    if (token == null) return TransactionStatus.unknown;

    try {
      final ts = _timestamp();
      final rawPw =
          '${ApiKeys.mpesaBusinessShortCode}${ApiKeys.mpesaPasskey}$ts';
      final password = base64Encode(utf8.encode(rawPw));

      final res = await http
          .post(
            Uri.parse('$_baseUrl/mpesa/stkpushquery/v1/query'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'BusinessShortCode': ApiKeys.mpesaBusinessShortCode,
              'Password': password,
              'Timestamp': ts,
              'CheckoutRequestID': checkoutRequestId,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final resultCode = data['ResultCode']?.toString();
        switch (resultCode) {
          case '0':
            return TransactionStatus.success;
          case '1032':
            return TransactionStatus.cancelled;
          case '1':
            return TransactionStatus.insufficientBalance;
          case '1037':
            // STK prompt timed out — keep polling so the user has the full window.
            return TransactionStatus.pending;
          case '4999':
            // Daraja is still processing the transaction — not a failure.
            return TransactionStatus.pending;
          default:
            // Any response without a ResultCode key = Daraja still processing.
            if (data.containsKey('ResultCode')) return TransactionStatus.failed;
            return TransactionStatus.pending;
        }
      }
      // 429 = rate-limited; 500 = still processing. Both are transient — keep polling.
      return TransactionStatus.pending;
    } catch (_) {
      return TransactionStatus.unknown;
    }
  }
}
