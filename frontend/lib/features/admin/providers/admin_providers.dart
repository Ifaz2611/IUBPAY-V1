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
final dailyReportFamilyProvider = FutureProvider.family<List<dynamic>, int>((ref, days) async {
  final r = await ref.read(dioProvider).get('/admin/reports/daily?days=$days');
  return List<dynamic>.from(r.data);
});
final transactionsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final r = await ref.read(dioProvider).get('/admin/reports/transactions');
  return Map<String, dynamic>.from(r.data);
});
final adminVendorsProvider = FutureProvider<List<dynamic>>((ref) async {
  final r = await ref.read(dioProvider).get('/vendors?include_all=true');
  return List<dynamic>.from(r.data);
});
final adminUsersProvider = FutureProvider<List<dynamic>>((ref) async {
  final r = await ref.read(dioProvider).get('/admin/users');
  return List<dynamic>.from(r.data);
});
