import 'package:flutter/foundation.dart';

/// Backend base URL.
/// Android emulator reaches host machine via 10.0.2.2; web/desktop uses localhost.
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue:
      kIsWeb ? 'http://localhost:8000/api' : 'http://10.0.2.2:8000/api',
);

const String kAppName = 'IUB PAY v1';
const String kDemoNotice =
    'DEMO / MOCK PAYMENTS — not connected to any real payment provider or IUB system.';
