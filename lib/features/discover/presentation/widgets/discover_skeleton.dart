import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';

/// A lightweight shimmer used for the Discover cold-start placeholder. Built with
/// a single animated gradient (no extra package) so it stays cheap.
class Shimmer extends StatefulWidget {
  final Widget child;
  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // El brillo del esqueleto se deriva del lienzo y la tarjeta del tema: era
    // un par de grises azulados fijos que en un tema cálido se veían fríos.
    final surfaces = Theme.of(context).surfaces;
    final base = Color.lerp(surfaces.canvas, surfaces.ink, 0.06)!;
    final shine = surfaces.card;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final dx = bounds.width * (_controller.value * 2 - 1);
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, shine, base],
              stops: const [0.35, 0.5, 0.65],
              transform: _SlideGradient(dx),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlideGradient extends GradientTransform {
  final double dx;
  const _SlideGradient(this.dx);
  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(dx, 0, 0);
}

/// Simple rounded grey block used as a shimmer building unit.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Color.lerp(
          Theme.of(context).surfaces.canvas,
          Theme.of(context).surfaces.ink,
          0.06,
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// The full Discover cold-start placeholder: hero + a rail + a couple of rows.
class DiscoverSkeleton extends StatelessWidget {
  const DiscoverSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const SkeletonBox(height: 150, radius: 24),
          const SizedBox(height: 24),
          const SkeletonBox(width: 140, height: 20),
          const SizedBox(height: 14),
          SizedBox(
            height: 150,
            child: Row(
              children: const [
                Expanded(child: SkeletonBox(height: 150, radius: 20)),
                SizedBox(width: 14),
                Expanded(child: SkeletonBox(height: 150, radius: 20)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SkeletonBox(width: 160, height: 20),
          const SizedBox(height: 14),
          for (var i = 0; i < 3; i++) ...[
            const SkeletonBox(height: 76, radius: 18),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
