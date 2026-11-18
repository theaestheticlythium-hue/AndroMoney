import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Reusable dark liquid background with soft coloured light blooms.
class LiquidGlassBackground extends StatelessWidget {
  final Widget child;
  final bool safeArea;

  const LiquidGlassBackground({
    super.key,
    required this.child,
    this.safeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF101A22),
                AppTheme.background,
                Color(0xFF080F18),
              ],
            ),
          ),
        ),
        const _GlowBlob(
          alignment: Alignment(-1.1, -0.9),
          color: Color(0x5500E676),
          size: 230,
        ),
        const _GlowBlob(
          alignment: Alignment(1.15, 0.05),
          color: Color(0x443D8BFF),
          size: 250,
        ),
        const _GlowBlob(
          alignment: Alignment(0.2, 1.15),
          color: Color(0x3326C6A5),
          size: 230,
        ),
        child,
      ],
    );

    return safeArea ? SafeArea(child: content) : content;
  }
}

class _GlowBlob extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final double size;

  const _GlowBlob({
    required this.alignment,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 75, sigmaY: 75),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Frosted translucent panel. Place over [LiquidGlassBackground] for blur.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? tint;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.tint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final panel = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (tint ?? const Color(0xFFBFC8D2)).withValues(alpha: 0.15),
                const Color(0xFF7E8B98).withValues(alpha: 0.055),
              ],
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) return panel;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: panel,
      ),
    );
  }
}

class GlassSectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const GlassSectionTitle(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
