import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';

/// Waits for the auth token check, then lets the router redirect onward.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) context.go('/');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B3A6B),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_menu,
                size: 88, color: Colors.white),
            const SizedBox(height: 16),
            Text(kAppName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Cashless Campus Ordering — PROTOTYPE',
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(kDemoNotice,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }
}
