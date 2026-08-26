import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/api/api_client.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';
import '../utils/money_formatter.dart';

// ─── helpers ──────────────────────────────────────────────────
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Stack(children: [
          // ambient glows
          Positioned(
            top: -120, right: -80,
            child: Container(width: 340, height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [AppColors.neonCyan.withOpacity(0.18), Colors.transparent]),
              ),
            ),
          ),
          Positioned(
            bottom: -100, left: -60,
            child: Container(width: 380, height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [AppColors.neonPurple.withOpacity(0.14), Colors.transparent]),
              ),
            ),
          ),
          Positioned(
            top: 320, left: 40,
            child: Container(width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [AppColors.neonPink.withOpacity(0.08), Colors.transparent]),
              ),
            ),
          ),
          child,
        ]),
      );
}

/// Glass-morphism card
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;
  final double blur;
  const GlassCard({
    super.key, required this.child,
    this.padding, this.margin,
    this.borderRadius = 20, this.shadows, this.onTap, this.blur = 18,
  });
  @override
  Widget build(BuildContext context) {
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.03)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withOpacity(0.10), width: 1),
            boxShadow: shadows ?? [
              BoxShadow(color: Colors.black.withOpacity(0.28), blurRadius: 24, offset: const Offset(0, 10)),
            ],
          ),
          child: child,
        ),
      ),
    );
    if (onTap != null) {
      return Padding(
        padding: margin ?? EdgeInsets.zero,
        child: Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(borderRadius), onTap: onTap, child: card)),
      );
    }
    return Container(margin: margin, child: card);
  }
}

/// Neon gradient button
class NeonButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool busy;
  final List<Color> gradient;
  const NeonButton({super.key, required this.label, this.icon, this.onPressed, this.busy = false, this.gradient = const [AppColors.neonCyan, AppColors.neonPurple]});
  @override
  Widget build(BuildContext context) => Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: gradient.first.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: busy ? null : onPressed,
            child: Center(
              child: busy
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      if (icon != null) ...[Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 8)],
                      Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.4)),
                    ]),
            ),
          ),
        ),
      );
}

// ─── status badge — neon pill ─────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  static const _map = {
    'PENDING_PAYMENT': (AppColors.neonAmber, Icons.schedule_rounded, 'Awaiting payment'),
    'PAYMENT_PROCESSING': (AppColors.neonAmber, Icons.hourglass_top_rounded, 'Processing'),
    'PAYMENT_FAILED': (AppColors.neonRed, Icons.error_outline_rounded, 'Payment failed'),
    'PAID': (AppColors.neonCyan, Icons.verified_rounded, 'Paid ✓'),
    'ACCEPTED': (AppColors.neonPurple, Icons.thumb_up_rounded, 'Accepted'),
    'PREPARING': (Color(0xFFFF6D00), Icons.soup_kitchen_rounded, 'Preparing'),
    'READY': (AppColors.neonGreen, Icons.notifications_active_rounded, 'Ready!'),
    'COLLECTED': (AppColors.neonGreen, Icons.check_circle_rounded, 'Collected'),
    'CANCELLED': (AppColors.textTertiary, Icons.cancel_rounded, 'Cancelled'),
    'REJECTED': (AppColors.neonRed, Icons.block_rounded, 'Rejected'),
    'REFUND_PENDING': (Color(0xFFFF9100), Icons.undo_rounded, 'Refunding'),
    'REFUNDED': (AppColors.neonPurple, Icons.reply_rounded, 'Refunded'),
  };

  @override
  Widget build(BuildContext context) {
    final v = _map[status];
    final Color c = (v?.$1) ?? AppColors.textSecondary;
    final IconData ic = (v?.$2) ?? Icons.circle;
    final String label = (v?.$3) ?? status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: c.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.45), width: 1),
        boxShadow: [BoxShadow(color: c.withOpacity(0.22), blurRadius: 12)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(ic, size: 14, color: c),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 12.5, letterSpacing: 0.3)),
      ]),
    );
  }
}

// ─── price ──────────────────────────────────────────────────────
class PriceText extends StatelessWidget {
  final int amount;
  final double fontSize;
  final bool bold;
  final Color? color;
  const PriceText(this.amount, {super.key, this.fontSize = 16, this.bold = true, this.color});
  @override
  Widget build(BuildContext context) => ShaderMask(
        shaderCallback: (b) => const LinearGradient(colors: [AppColors.neonCyan, AppColors.neonPurple]).createShader(b),
        child: Text(taka(amount),
            style: TextStyle(
                fontSize: fontSize,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.3)),
      );
}

const demoBanner = SnackBar(content: Text(kDemoNotice));

// ─── loading / empty / error ────────────────────────────────────
class LoadingView extends StatelessWidget {
  final String? message;
  const LoadingView({super.key, this.message});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // neon ring loader
          SizedBox(
            width: 52, height: 52,
            child: Stack(alignment: Alignment.center, children: [
              Container(width: 52, height: 52, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.08), width: 2))),
              const SizedBox(width: 44, height: 44, child: CircularProgressIndicator(strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation(AppColors.neonCyan))),
              Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.neonCyan, boxShadow: [BoxShadow(color: AppColors.neonCyan.withOpacity(0.6), blurRadius: 10)])),
            ]),
          ),
          if (message != null) ...[
            const SizedBox(height: 14),
            Text(message!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ]
        ]),
      );
}

class EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  const EmptyView({super.key, this.icon = Icons.inbox_outlined, required this.message});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 84, height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Icon(icon, size: 36, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4)),
          ]),
        ),
      );
}

class ErrorView extends ConsumerWidget {
  final Object error;
  final VoidCallback onRetry;
  const ErrorView({super.key, required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.neonRed.withOpacity(0.10), border: Border.all(color: AppColors.neonRed.withOpacity(0.2))),
              child: const Icon(Icons.wifi_off_rounded, size: 36, color: AppColors.neonRed),
            ),
            const SizedBox(height: 16),
            Text(apiErrorMessage(error), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 18),
            NeonButton(label: 'Retry', icon: Icons.refresh_rounded, onPressed: onRetry, gradient: const [AppColors.neonRed, Color(0xFFFF6E40)]),
          ]),
        ),
      );
}

class MockPaymentBanner extends StatelessWidget {
  const MockPaymentBanner({super.key});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.neonAmber.withOpacity(0.18), AppColors.neonAmber.withOpacity(0.06)]),
          border: Border(bottom: BorderSide(color: AppColors.neonAmber.withOpacity(0.25))),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppColors.neonAmber.withOpacity(0.20), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.science_rounded, size: 16, color: AppColors.neonAmber),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Text('DEMO MODE  •  $kDemoNotice', style: TextStyle(fontSize: 11.5, color: AppColors.neonAmber, fontWeight: FontWeight.w700, letterSpacing: 0.2))),
        ]),
      );
}

/// Section header with neon accent line
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  const SectionHeader({super.key, required this.title, this.subtitle, this.action});
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(width: 3, height: 22, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.neonCyan, AppColors.neonPurple], begin: Alignment.topCenter, end: Alignment.bottomCenter), borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
          if (subtitle != null) Text(subtitle!, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
        ])),
        if (action != null) action!,
      ]);
}
