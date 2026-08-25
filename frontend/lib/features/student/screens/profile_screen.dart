import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(user?.name ?? ''),
            subtitle: Text(user?.email ?? ''),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Student ID'),
            trailing: Text(user?.studentId ?? '—'),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: const Text('Role'),
            trailing: Text(user?.role.toUpperCase() ?? ''),
          ),
        ),
        const SizedBox(height: 16),
        const Card(
          color: Color(0xFFFFF3CD),
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Text(kDemoNotice,
                style: TextStyle(fontSize: 12.5)),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade400),
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
          onPressed: () async {
            await ref.read(authProvider.notifier).logout();
            if (context.mounted) context.go('/login');
          },
        ),
      ]),
    );
  }
}
