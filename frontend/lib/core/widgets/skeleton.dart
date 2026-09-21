import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// ─── Base pulse skeleton ───────────────────────────────────────────────────
/// Grey wireframe that gently pulses — no external dependency needed.
/// Uses surfaceMuted/border tokens so it adapts to light & dark.
class SkeletonBox extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.margin,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _a = Tween<double>(begin: 0.45, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) => Opacity(
        opacity: _a.value,
        child: Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            color: c.surfaceMuted,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(6),
            border: Border.all(color: c.border.withOpacity(0.6), width: 1),
          ),
        ),
      ),
    );
  }
}

class SkeletonCircle extends StatelessWidget {
  final double size;
  const SkeletonCircle(this.size, {super.key});
  @override
  Widget build(BuildContext context) => SkeletonBox(
        width: size,
        height: size,
        borderRadius: BorderRadius.circular(999),
      );
}

/// Shimmer sweep — gradient slides over child to feel more "loading".
/// Lightweight implementation without external package.
class Shimmer extends StatefulWidget {
  final Widget child;
  const Shimmer({super.key, required this.child});
  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final base = c.surfaceMuted;
    final highlight = c.surfaceHover.withOpacity(0.7);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: [base, highlight, base],
          stops: const [0.2, 0.5, 0.8],
          begin: Alignment(-1.0 + 2 * _c.value, 0),
          end: Alignment(1.0 + 2 * _c.value, 0),
        ).createShader(bounds),
        blendMode: BlendMode.srcATop,
        child: widget.child,
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────
Widget _skeletonCard({required Widget child, EdgeInsetsGeometry? padding}) {
  return Builder(builder: (context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: context.appColors.border),
      ),
      child: child,
    );
  });
}

// ─── Vendor list skeleton ────────────────────────────────────────────────────
class VendorListSkeleton extends StatelessWidget {
  final int count;
  const VendorListSkeleton({super.key, this.count = 6});
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => _VendorRowSkeleton(),
    );
  }
}

class _VendorRowSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _skeletonCard(
      child: Row(children: [
        const SkeletonBox(width: 56, height: 56, borderRadius: BorderRadius.all(Radius.circular(12))),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Expanded(child: SkeletonBox(height: 14, borderRadius: BorderRadius.all(Radius.circular(4)))),
              const SizedBox(width: 12),
              const SkeletonCircle(28),
            ]),
            const SizedBox(height: 8),
            const SkeletonBox(height: 11, width: 140),
            const SizedBox(height: 8),
            Row(children: [
              SkeletonBox(height: 20, width: 56, borderRadius: BorderRadius.circular(20)),
              const SizedBox(width: 6),
              SkeletonBox(height: 20, width: 44, borderRadius: BorderRadius.circular(6)),
              const SizedBox(width: 6),
              SkeletonBox(height: 20, width: 74, borderRadius: BorderRadius.circular(6)),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class VendorGridSkeleton extends StatelessWidget {
  final int count;
  const VendorGridSkeleton({super.key, this.count = 6});
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.92,
      ),
      itemCount: count,
      itemBuilder: (_, __) => const _VendorGridSkeletonCard(),
    );
  }
}

class _VendorGridSkeletonCard extends StatelessWidget {
  const _VendorGridSkeletonCard();
  @override
  Widget build(BuildContext context) {
    return _skeletonCard(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const SkeletonBox(width: 44, height: 44, borderRadius: BorderRadius.all(Radius.circular(10))),
          const Spacer(),
          const SkeletonCircle(26),
        ]),
        const SizedBox(height: 12),
        const SkeletonBox(height: 12, width: 110),
        const SizedBox(height: 6),
        const SkeletonBox(height: 10, width: 90),
        const Spacer(),
        Row(children: [
          SkeletonBox(height: 16, width: 48, borderRadius: BorderRadius.circular(6)),
          const SizedBox(width: 8),
          const SkeletonBox(height: 10, width: 36),
        ]),
        const SizedBox(height: 6),
        const SkeletonBox(height: 10, width: double.infinity),
      ]),
    );
  }
}

// ─── Featured carousel skeleton (student home) ───────────────────────────────
class FeaturedVendorsSkeleton extends StatelessWidget {
  const FeaturedVendorsSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const SkeletonBox(height: 14, width: 140),
        const Spacer(),
        SkeletonBox(height: 28, width: 64, borderRadius: BorderRadius.circular(8)),
      ]),
      const SizedBox(height: 10),
      SizedBox(
        height: 150,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, __) => Container(
            width: 160,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.appColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: context.appColors.border),
            ),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                SkeletonBox(width: 40, height: 40, borderRadius: BorderRadius.all(Radius.circular(10))),
                Spacer(),
                SkeletonBox(width: 44, height: 20, borderRadius: BorderRadius.all(Radius.circular(20))),
              ]),
              SizedBox(height: 14),
              SkeletonBox(height: 12, width: 110),
              SizedBox(height: 6),
              SkeletonBox(height: 10, width: 90),
              Spacer(),
              SkeletonBox(height: 10, width: 100),
            ]),
          ),
        ),
      ),
    ]);
  }
}

// ─── Menu skeleton ───────────────────────────────────────────────────────────
class MenuListSkeleton extends StatelessWidget {
  final int count;
  const MenuListSkeleton({super.key, this.count = 6});
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => const _MenuRowSkeleton(),
    );
  }
}

class _MenuRowSkeleton extends StatelessWidget {
  const _MenuRowSkeleton();
  @override
  Widget build(BuildContext context) {
    return _skeletonCard(
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        const SkeletonBox(width: 64, height: 64, borderRadius: BorderRadius.all(Radius.circular(12))),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Expanded(child: SkeletonBox(height: 13, width: 120)),
              const SizedBox(width: 8),
              const SkeletonCircle(16),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              SkeletonBox(height: 14, width: 48, borderRadius: BorderRadius.circular(4)),
              const SizedBox(width: 6),
              SkeletonBox(height: 16, width: 56, borderRadius: BorderRadius.circular(5)),
            ]),
            const SizedBox(height: 6),
            const SkeletonBox(height: 10, width: double.infinity),
            const SizedBox(height: 4),
            const SkeletonBox(height: 10, width: 160),
            const SizedBox(height: 6),
            Row(children: [
              const SkeletonBox(height: 10, width: 44),
              const SizedBox(width: 8),
              const SkeletonBox(height: 10, width: 40),
            ]),
          ]),
        ),
        const SizedBox(width: 10),
        SkeletonBox(height: 36, width: 56, borderRadius: BorderRadius.circular(8)),
      ]),
    );
  }
}

// ─── Order list skeleton ─────────────────────────────────────────────────────
class OrderListSkeleton extends StatelessWidget {
  final int count;
  const OrderListSkeleton({super.key, this.count = 5});
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => const _OrderRowSkeleton(),
    );
  }
}

class _OrderRowSkeleton extends StatelessWidget {
  const _OrderRowSkeleton();
  @override
  Widget build(BuildContext context) {
    return _skeletonCard(
      child: Row(children: [
        const SkeletonBox(width: 40, height: 40, borderRadius: BorderRadius.all(Radius.circular(10))),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Expanded(child: SkeletonBox(height: 12, width: 100)),
              const SizedBox(width: 8),
              SkeletonBox(height: 22, width: 72, borderRadius: BorderRadius.circular(20)),
            ]),
            const SizedBox(height: 8),
            const SkeletonBox(height: 10, width: 180),
          ]),
        ),
      ]),
    );
  }
}

// ─── Student home skeleton ───────────────────────────────────────────────────
class StudentHomeSkeleton extends StatelessWidget {
  const StudentHomeSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SkeletonBox(height: 48, borderRadius: BorderRadius.all(Radius.circular(12))),
        const SizedBox(height: 14),
        _skeletonCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const SkeletonBox(height: 10, width: 60),
              SkeletonBox(height: 20, width: 64, borderRadius: BorderRadius.circular(20)),
            ]),
            const SizedBox(height: 12),
            const SkeletonBox(height: 14, width: 180),
            const SizedBox(height: 8),
            const SkeletonBox(height: 18, width: 110, borderRadius: BorderRadius.all(Radius.circular(6))),
            const SizedBox(height: 14),
            Container(height: 1, color: context.appColors.border),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [SkeletonBox(height: 10, width: 54), const SizedBox(height: 6), SkeletonBox(height: 16, width: 28)])),
              Container(width: 1, height: 42, color: context.appColors.border),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [SkeletonBox(height: 10, width: 54), const SizedBox(height: 6), SkeletonBox(height: 16, width: 28)])),
              Container(width: 1, height: 42, color: context.appColors.border),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [SkeletonBox(height: 10, width: 54), const SizedBox(height: 6), SkeletonBox(height: 16, width: 28)])),
            ]),
          ]),
        ),
        const SizedBox(height: 20),
        const SkeletonBox(height: 14, width: 120),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0,
          children: List.generate(4, (_) => _skeletonCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [SkeletonBox(width: 40, height: 40, borderRadius: BorderRadius.all(Radius.circular(10))), const Spacer(), SkeletonBox(width: 40, height: 18, borderRadius: BorderRadius.all(Radius.circular(20))) ]), const Spacer(), SkeletonBox(height: 12, width: 100), const SizedBox(height: 6), SkeletonBox(height: 10, width: 80)]))),
        ),
        const SizedBox(height: 20),
        const FeaturedVendorsSkeleton(),
        const SizedBox(height: 20),
        ...List.generate(2, (_) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _skeletonCard(child: Row(children: [SkeletonBox(width: 44, height: 44, borderRadius: BorderRadius.all(Radius.circular(10))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [SkeletonBox(height: 12, width: 120), const SizedBox(height: 6), SkeletonBox(height: 10, width: 180)]))] )))),
      ],
    );
  }
}

// ─── Order tracking / receipt skeleton ──────────────────────────────────────
class OrderTrackingSkeleton extends StatelessWidget {
  const OrderTrackingSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _skeletonCard(
        child: Column(children: [
          const SkeletonBox(height: 24, width: 100, borderRadius: BorderRadius.all(Radius.circular(20))),
          const SizedBox(height: 16),
          Row(children: [
            const Expanded(child: Column(children: [SkeletonBox(height: 10, width: 70), SizedBox(height: 8), SkeletonBox(height: 22, width: 80)])),
            Container(width: 1, height: 48, color: context.appColors.border),
            const Expanded(child: Column(children: [SkeletonBox(height: 10, width: 50), SizedBox(height: 8), SkeletonBox(height: 18, width: 70)])),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      _skeletonCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SkeletonBox(height: 14, width: 80),
          const SizedBox(height: 14),
          ...List.generate(5, (_) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [SkeletonCircle(24), const SizedBox(width: 12), Expanded(child: SkeletonBox(height: 12, width: 120)), SkeletonBox(height: 18, width: 36, borderRadius: BorderRadius.all(Radius.circular(6)))]))),
        ]),
      ),
      const SizedBox(height: 12),
      _skeletonCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [SkeletonBox(height: 13, width: 60), const SizedBox(height: 12), ...List.generate(3, (_) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [Expanded(child: SkeletonBox(height: 12, width: 100)), const SizedBox(width: 12), SkeletonBox(height: 12, width: 70)])))])),
    ]);
  }
}

class ReceiptSkeleton extends StatelessWidget {
  const ReceiptSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: context.appColors.surface, borderRadius: BorderRadius.circular(AppRadii.lg), border: Border.all(color: context.appColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Center(child: SkeletonBox(height: 18, width: 70, borderRadius: BorderRadius.all(Radius.circular(6)))),
          const SizedBox(height: 12),
          const Center(child: SkeletonBox(height: 12, width: 120)),
          const SizedBox(height: 14),
          ...List.generate(3, (_) => const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [SkeletonBox(height: 12, width: 100), SizedBox(height: 4), SkeletonBox(height: 10, width: 80)] )), SkeletonBox(height: 12, width: 50)]))),
          const SizedBox(height: 12),
          const SkeletonBox(height: 1, width: double.infinity),
          const SizedBox(height: 12),
          const SkeletonBox(height: 12, width: double.infinity),
        ]),
      ),
    );
  }
}

// ─── Cart skeleton ───────────────────────────────────────────────────────────
class CartSkeleton extends StatelessWidget {
  const CartSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      ...List.generate(3, (_) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _skeletonCard(child: Row(children: [SkeletonBox(width: 48, height: 48, borderRadius: BorderRadius.all(Radius.circular(10))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [SkeletonBox(height: 13, width: 120), const SizedBox(height: 6), SkeletonBox(height: 10, width: 160)] )), SkeletonBox(height: 32, width: 96, borderRadius: BorderRadius.all(Radius.circular(10)))])))),
    ]);
  }
}

// ─── Generic admin/vendor KPI skeleton with shimmer ──────────────────────────
class KpiGridSkeleton extends StatelessWidget {
  final int count;
  final int crossAxisCount;
  const KpiGridSkeleton({super.key, this.count = 8, this.crossAxisCount = 4});
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: List.generate(
        count,
        (_) => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: context.appColors.surface, borderRadius: BorderRadius.circular(AppRadii.lg), border: Border.all(color: context.appColors.border)),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [SkeletonBox(width: 32, height: 32, borderRadius: BorderRadius.all(Radius.circular(8))), Spacer(), SkeletonBox(width: 40, height: 18, borderRadius: BorderRadius.all(Radius.circular(6)))]),
            Spacer(),
            SkeletonBox(height: 10, width: 70),
            SizedBox(height: 6),
            SkeletonBox(height: 18, width: 80),
            SizedBox(height: 4),
            SkeletonBox(height: 10, width: 100),
          ]),
        ),
      ),
    );
  }
}

// ─── User list skeleton ──────────────────────────────────────────────────────
class UserListSkeleton extends StatelessWidget {
  const UserListSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => _skeletonCard(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          const SkeletonCircle(36),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [SkeletonBox(height: 12, width: 120), SizedBox(height: 6), SkeletonBox(height: 10, width: 180)])),
          SkeletonBox(height: 22, width: 56, borderRadius: BorderRadius.circular(6)),
        ]),
      ),
    );
  }
}

// ─── Vendor queue / menu health generic ─────────────────────────────────────
class ListSkeleton extends StatelessWidget {
  final int count;
  const ListSkeleton({super.key, this.count = 4});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (_) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: _skeletonCard(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              const SkeletonBox(width: 36, height: 36, borderRadius: BorderRadius.all(Radius.circular(8))),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [SkeletonBox(height: 12, width: 120), SizedBox(height: 6), SkeletonBox(height: 10, width: 160)])),
              SkeletonBox(height: 28, width: 64, borderRadius: BorderRadius.circular(6)),
            ]),
          ),
        ),
      ),
    );
  }
}
