import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/api/api_client.dart';

final adminSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final r = await ref.read(dioProvider).get('/admin/reports/summary');
  return Map<String, dynamic>.from(r.data);
});
final dailyReportProvider = FutureProvider<List<dynamic>>((ref) async {
  final r = await ref.read(dioProvider).get('/admin/reports/daily?days=14');
  return List<dynamic>.from(r.data);
});
final dailyReportFamilyProvider =
    FutureProvider.family<List<dynamic>, int>((ref, days) async {
  final r = await ref.read(dioProvider).get('/admin/reports/daily?days=$days');
  return List<dynamic>.from(r.data);
});
final transactionsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final r = await ref.read(dioProvider).get('/admin/reports/transactions');
  return Map<String, dynamic>.from(r.data);
});
List<dynamic> _extractList(dynamic data) {
  if (data is List) return List<dynamic>.from(data);
  if (data is Map && data['items'] is List)
    return List<dynamic>.from(data['items'] as List);
  return [];
}

final adminVendorsProvider = FutureProvider<List<dynamic>>((ref) async {
  final r = await ref.read(dioProvider).get('/vendors?include_all=true');
  return _extractList(r.data);
});

/// Default page size for the admin user directory.
const kAdminUsersPageSize = 50;

/// Paginated user directory. Returns the raw enveloped response
/// `{items, total, limit, offset}` so the UI can page and show totals.
final adminUsersPageProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, offset) async {
  final r = await ref.read(dioProvider).get(
        '/admin/users',
        queryParameters: {
          'limit': kAdminUsersPageSize,
          'offset': offset,
        },
      );
  return Map<String, dynamic>.from(r.data);
});

/// Total user count (from the paginated endpoint) for KPI displays.
final adminUsersTotalProvider = FutureProvider<int>((ref) async {
  final r = await ref.read(dioProvider).get(
        '/admin/users',
        queryParameters: {'limit': 1, 'offset': 0},
      );
  if (r.data is Map) return (r.data['total'] as num?)?.toInt() ?? 0;
  return (r.data as List).length;
});

/// Backward-compatible list provider (first page) used by the dashboard
/// overview card.
final adminUsersProvider = FutureProvider<List<dynamic>>((ref) async {
  final page = await ref.watch(adminUsersPageProvider(0).future);
  return List<dynamic>.from(page['items'] as List);
});
