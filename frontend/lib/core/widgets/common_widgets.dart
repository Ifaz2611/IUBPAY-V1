import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/api/api_client.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../utils/money_formatter.dart';

// ─── App background — calm warm canvas ────────────────────────
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
        color: context.appColors.background,
        child: child,
      );
}

// ─── Theme toggle button — light/dark ────────────────────────
class ThemeToggleButton extends ConsumerWidget {
  final bool compact;
  const ThemeToggleButton({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final isDark = mode == ThemeMode.dark ||
        (mode == ThemeMode.system && MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final icon = isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded;
    final tooltip = isDark ? 'Switch to light mode' : 'Switch to dark mode';
    if (compact) {
      return IconButton(
        icon: Icon(icon, size: 20),
        tooltip: tooltip,
        onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
      );
    }
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
    );
  }
}

class ThemeToggleTile extends ConsumerWidget {
  const ThemeToggleTile({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final isDark = mode == ThemeMode.dark ||
        (mode == ThemeMode.system && MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final c = context.appColors;
    return AppCard(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: BorderRadius.circular(8), border: Border.all(color: c.border)),
          child: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, size: 16, color: c.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isDark ? 'Dark mode' : 'Light mode', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
            Text(isDark ? 'Dark • easy on eyes' : 'Light • classic', style: TextStyle(color: c.textTertiary, fontSize: 11)),
          ]),
        ),
        Switch(
          value: isDark,
          activeThumbColor: c.brand,
          onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
        ),
      ]),
    );
  }
}

// ─── App bar — simple, trustworthy ────────────────────────────
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final bool showBack;
  final VoidCallback? onBack;
  final bool showThemeToggle;

  const AppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.showBack = true,
    this.onBack,
    this.showThemeToggle = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return AppBar(
      leading: showBack
          ? IconButton(
              icon: Icon(Icons.arrow_back_rounded),
              onPressed: onBack ??
                  () {
                    if (context.canPop()) context.pop();
                  },
            )
          : null,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          if (subtitle != null)
            Text(subtitle!,
                style: TextStyle(color: c.textTertiary, fontSize: 12, fontWeight: FontWeight.w400)),
        ],
      ),
      actions: [
        if (showThemeToggle) const ThemeToggleButton(),
        if (action != null) Padding(padding: const EdgeInsets.only(right: 8), child: action!),
        if (action == null && !showThemeToggle) const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: c.border),
      ),
    );
  }
}

// ─── Card — solid surface, thin border, soft shadow ──────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = AppRadii.lg,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final isDark = context.isDarkMode;
    final card = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: c.border, width: 1),
        boxShadow: isDark ? AppShadows.cardDark : AppShadows.card,
      ),
      child: child,
    );
    if (onTap != null) {
      return Padding(
        padding: margin ?? EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadius),
            onTap: onTap,
            child: card,
          ),
        ),
      );
    }
    return Container(margin: margin, child: card);
  }
}

// Legacy alias — keeps old screens compiling while migrating
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;
  final double blur;
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = AppRadii.lg,
    this.shadows,
    this.onTap,
    this.blur = 0,
  });
  @override
  Widget build(BuildContext context) => AppCard(
        padding: padding,
        margin: margin,
        borderRadius: borderRadius,
        onTap: onTap,
        child: child,
      );
}

// ─── Primary button — solid brand, clear states ──────────────
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool busy;
  final bool outlined;
  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.busy = false,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = busy
        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
        : Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
            if (icon != null) ...[Icon(icon, size: 18), SizedBox(width: 8)],
            Text(label),
          ]);
    if (outlined) {
      return SizedBox(
        height: 48,
        width: double.infinity,
        child: OutlinedButton(onPressed: busy ? null : onPressed, child: child),
      );
    }
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: FilledButton(onPressed: busy ? null : onPressed, child: child),
    );
  }
}

// Legacy alias
class NeonButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool busy;
  final List<Color> gradient;
  NeonButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.busy = false,
    this.gradient = const [Color(0xFF0F5B4A), Color(0xFF0F5B4A)],
  });
  @override
  Widget build(BuildContext context) => PrimaryButton(label: label, icon: icon, onPressed: onPressed, busy: busy);
}

// ─── Status chip — muted, semantic ────────────────────────────
class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final map = {
      'PENDING_PAYMENT': (c.warning, c.warningBg, 'Awaiting payment'),
      'PAYMENT_PROCESSING': (c.warning, c.warningBg, 'Processing'),
      'PAYMENT_FAILED': (c.error, c.errorBg, 'Payment failed'),
      'PAID': (c.success, c.successBg, 'Paid'),
      'ACCEPTED': (c.info, c.infoBg, 'Accepted'),
      'PREPARING': (c.accentAmber, c.accentAmberBg, 'Preparing'),
      'READY': (c.success, c.successBg, 'Ready for pickup'),
      'COLLECTED': (c.textSecondary, c.surfaceMuted, 'Collected'),
      'CANCELLED': (c.textTertiary, c.surfaceMuted, 'Cancelled'),
      'REJECTED': (c.error, c.errorBg, 'Rejected'),
      'REFUND_PENDING': (c.warning, c.warningBg, 'Refunding'),
      'REFUNDED': (c.textSecondary, c.surfaceMuted, 'Refunded'),
    };
    final v = map[status];
    final Color fg = (v?.$1) ?? c.textSecondary;
    final Color bg = (v?.$2) ?? c.surfaceMuted;
    final String label = (v?.$3) ?? status.replaceAll('_', ' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: fg.withOpacity(0.18), width: 1),
      ),
      child: Text(label,
          style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 11.5, letterSpacing: 0.15)),
    );
  }
}

// Legacy alias
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});
  @override
  Widget build(BuildContext context) => StatusChip(status: status);
}

// ─── Price text — uses centralized taka() ─────────────────────
class PriceText extends StatelessWidget {
  final int amount;
  final double fontSize;
  final bool bold;
  final Color? color;
  const PriceText(this.amount, {super.key, this.fontSize = 16, this.bold = true, this.color});
  @override
  Widget build(BuildContext context) => Text(
        taka(amount),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: color ?? context.appColors.textPrimary,
          letterSpacing: -0.2,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
}

const demoBanner = SnackBar(content: Text(kDemoNotice));

// ─── Loading / Empty / Error ──────────────────────────────────
class LoadingView extends StatelessWidget {
  final String? message;
  const LoadingView({super.key, this.message});
  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.2, color: c.brand)),
            if (message != null) ...[
              const SizedBox(height: 12),
              Text(message!, style: TextStyle(color: c.textSecondary, fontSize: 13)),
            ]
          ]),
        ),
      );
  }
}

class EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const EmptyView({super.key, this.icon = Icons.inbox_outlined, required this.message, this.actionLabel, this.onAction});
  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.surfaceMuted,
                border: Border.all(color: c.border),
              ),
              child: Icon(icon, size: 28, color: c.textTertiary),
            ),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary, fontSize: 14, height: 1.4)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(onPressed: onAction, icon: Icon(Icons.refresh_rounded, size: 16), label: Text(actionLabel!)),
            ]
          ]),
        ),
      );
  }
}

class ErrorView extends ConsumerWidget {
  final Object error;
  final VoidCallback onRetry;
  const ErrorView({super.key, required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(shape: BoxShape.circle, color: c.errorBg, border: Border.all(color: c.errorBorder)),
              child: Icon(Icons.wifi_off_rounded, size: 28, color: c.error),
            ),
            const SizedBox(height: 14),
            Text(apiErrorMessage(error), textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.4)),
            const SizedBox(height: 16),
            PrimaryButton(label: 'Try again', icon: Icons.refresh_rounded, onPressed: onRetry),
          ]),
        ),
      );
  }
}

class MockPaymentBanner extends StatelessWidget {
  const MockPaymentBanner({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: c.warningBg,
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        child: Row(children: [
          Icon(Icons.info_outline_rounded, size: 14, color: c.warning),
          const SizedBox(width: 8),
          Expanded(
              child: Text('Demo mode — payments are simulated and no real money moves.',
                  style: TextStyle(fontSize: 12, color: c.textSecondary))),
        ]),
      );
  }
}

/// Section header — plain, no neon accent
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  const SectionHeader({super.key, required this.title, this.subtitle, this.action});
  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Row(children: [
        Flexible(
            fit: FlexFit.loose,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.2)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: TextStyle(color: c.textTertiary, fontSize: 12)),
              ]
            ])),
        if (action != null) ...[
          const SizedBox(width: 12),
          action!,
        ],
      ]);
  }
}

/// Thin list row helper
class AppListRow extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const AppListRow({super.key, required this.leading, required this.title, this.subtitle, this.trailing, this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        leading,
        const SizedBox(width: 12),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: TextStyle(color: c.textTertiary, fontSize: 12)),
          ]
        ])),
        if (trailing != null) trailing!,
      ]),
    );
    if (onTap != null) {
      return Material(color: Colors.transparent, child: InkWell(onTap: onTap, child: row));
    }
    return row;
  }
}