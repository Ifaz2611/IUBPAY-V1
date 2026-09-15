import 'package:flutter/foundation.dart';

/// Backend base URL.
/// Android emulator reaches host machine via 10.0.2.2; web/desktop uses localhost.
/// In release builds HTTPS is enforced unless an explicit HTTPS override is provided.
const String _kApiBaseUrlEnv = String.fromEnvironment('API_BASE_URL', defaultValue: '');

String get kApiBaseUrl {
  final envUrl = _kApiBaseUrlEnv;
  if (envUrl.isNotEmpty) {
    if (kReleaseMode && envUrl.startsWith('http://')) {
      assert(false, 'API_BASE_URL must use HTTPS in release builds: $envUrl');
      // In release, force https if http was supplied
      return envUrl.replaceFirst('http://', 'https://');
    }
    return envUrl;
  }
  // Default URLs - http only allowed in debug/profile
  if (kReleaseMode) {
    // Production default should be https - configure via --dart-define=API_BASE_URL=https://...
    // Fallback enforces https scheme
    return 'https://api.iub-pay.example.com/api';
  }
  return kIsWeb ? 'http://localhost:8000/api' : 'http://10.0.2.2:8000/api';
}

const String kAppName = 'IUB PAY v1';
const String kDemoNotice =
    'DEMO / MOCK PAYMENTS — not connected to any real payment provider or IUB system.';
