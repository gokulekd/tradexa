// Angel One SmartAPI — credential storage and session token management.
// Credentials are saved to SharedPreferences once during setup.
// JWT/feedToken are refreshed on every login call (call once at app start).

import 'package:shared_preferences/shared_preferences.dart';

class AngelCredentials {
  final String apiKey;
  final String clientId;
  final String pin;
  final String totpSecret; // base32 TOTP secret from Angel One TOTP setup

  const AngelCredentials({
    required this.apiKey,
    required this.clientId,
    required this.pin,
    required this.totpSecret,
  });

  bool get isComplete =>
      apiKey.isNotEmpty &&
      clientId.isNotEmpty &&
      pin.isNotEmpty &&
      totpSecret.isNotEmpty;
}

class AngelSession {
  final String jwtToken;
  final String refreshToken;
  final String feedToken;
  final DateTime loginTime;

  const AngelSession({
    required this.jwtToken,
    required this.refreshToken,
    required this.feedToken,
    required this.loginTime,
  });

  // Tokens are valid for ~24 hours; treat as stale after 20 hours.
  bool get isExpired =>
      DateTime.now().difference(loginTime).inHours >= 20;
}

// ---------------------------------------------------------------------------
// Persistence helpers
// ---------------------------------------------------------------------------

const _kApiKey = 'angel_api_key';
const _kClientId = 'angel_client_id';
const _kPin = 'angel_pin';
const _kTotpSecret = 'angel_totp_secret';
const _kJwt = 'angel_jwt';
const _kRefresh = 'angel_refresh';
const _kFeed = 'angel_feed';
const _kLoginTime = 'angel_login_time';

Future<void> saveCredentials(AngelCredentials c) async {
  final p = await SharedPreferences.getInstance();
  await p.setString(_kApiKey, c.apiKey);
  await p.setString(_kClientId, c.clientId);
  await p.setString(_kPin, c.pin);
  await p.setString(_kTotpSecret, c.totpSecret);
}

Future<AngelCredentials?> loadCredentials() async {
  final p = await SharedPreferences.getInstance();
  final apiKey = p.getString(_kApiKey) ?? '';
  final clientId = p.getString(_kClientId) ?? '';
  final pin = p.getString(_kPin) ?? '';
  final totpSecret = p.getString(_kTotpSecret) ?? '';
  if (apiKey.isEmpty || clientId.isEmpty) return null;
  return AngelCredentials(
    apiKey: apiKey,
    clientId: clientId,
    pin: pin,
    totpSecret: totpSecret,
  );
}

Future<void> saveSession(AngelSession s) async {
  final p = await SharedPreferences.getInstance();
  await p.setString(_kJwt, s.jwtToken);
  await p.setString(_kRefresh, s.refreshToken);
  await p.setString(_kFeed, s.feedToken);
  await p.setString(_kLoginTime, s.loginTime.toIso8601String());
}

Future<AngelSession?> loadSession() async {
  final p = await SharedPreferences.getInstance();
  final jwt = p.getString(_kJwt) ?? '';
  final refresh = p.getString(_kRefresh) ?? '';
  final feed = p.getString(_kFeed) ?? '';
  final timeStr = p.getString(_kLoginTime) ?? '';
  if (jwt.isEmpty || timeStr.isEmpty) return null;
  return AngelSession(
    jwtToken: jwt,
    refreshToken: refresh,
    feedToken: feed,
    loginTime: DateTime.parse(timeStr),
  );
}

Future<void> clearSession() async {
  final p = await SharedPreferences.getInstance();
  await p.remove(_kJwt);
  await p.remove(_kRefresh);
  await p.remove(_kFeed);
  await p.remove(_kLoginTime);
}
