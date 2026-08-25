import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';

class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: Text('Hi, ${user?.name.split(' ').first ?? ''}')),
      drawer: Drawer(
        child: ListView(children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.name ?? ''),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture:
                const CircleAvatar(child: Icon(Icons.person)),
          ),
          ListTile(
              leading: const Icon(Icons.storefront),
              title: const Text('Browse food'),
              onTap: () => context.go('/student/vendors')),
          ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('My orders'),
              onTap: () => context.go('/student/orders')),
          ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Profile'),
              onTap: () => context.go('/student/profile')),
          const Divider(),
          ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              }),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(kDemoNotice,
                style: TextStyle(fontSize: 10.5, color: Colors.grey)),
          ),
        ]),
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
        children: [
          _Tile(Icons.storefront, 'Cafeterias',
              () => context.go('/student/vendors'), Colors.teal),
          _Tile(Icons.receipt_long, 'My Orders',
              () => context.go('/student/orders'), Colors.indigo),
          _Tile(Icons.shopping_cart, 'Cart', () => context.go('/student/cart'),
              Colors.orange),
          _Tile(Icons.person, 'Profile', () => context.go('/student/profile'),
              Colors.blueGrey),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _Tile(this.icon, this.label, this.onTap, this.color);

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}
