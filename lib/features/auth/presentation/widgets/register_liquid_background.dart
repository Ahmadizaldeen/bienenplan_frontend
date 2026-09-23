import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class RegisterLiquidBackground extends StatefulWidget {
  const RegisterLiquidBackground({super.key});

  @override
  State<RegisterLiquidBackground> createState() =>
      _RegisterLiquidBackgroundState();
}

class _RegisterLiquidBackgroundState extends State<RegisterLiquidBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.register.backgroundStart,
              AppColors.register.backgroundCenter,
              AppColors.register.backgroundEnd,
            ],
            stops: [0, .54, 1],
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final progress = Curves.easeInOut.transform(_controller.value);

            return Stack(
              fit: StackFit.expand,
              children: [
                Transform.translate(
                  offset: Offset(-190 + (360 * progress), -140),
                  child: Transform.rotate(
                    angle: -.28,
                    child: _LiquidLight(
                      color: AppColors.register.lightDeep,
                      widthFactor: 1.55,
                      height: 310,
                      opacity: .58,
                    ),
                  ),
                ),
                Transform.translate(
                  offset: Offset(140 - (300 * progress), 400),
                  child: Transform.rotate(
                    angle: .36,
                    child: _LiquidLight(
                      color: AppColors.register.lightAccent,
                      widthFactor: 1.45,
                      height: 230,
                      opacity: .52,
                    ),
                  ),
                ),
                Transform.translate(
                  offset: Offset(-220 + (200 * progress), 210),
                  child: Transform.rotate(
                    angle: .12,
                    child: _LiquidLight(
                      color: AppColors.register.lightMuted,
                      widthFactor: 1.6,
                      height: 270,
                      opacity: .42,
                    ),
                  ),
                ),
                Transform.translate(
                  offset: Offset(230 - (280 * progress), 680),
                  child: Transform.rotate(
                    angle: -.22,
                    child: _LiquidLight(
                      color: AppColors.register.lightDeep,
                      widthFactor: 1.35,
                      height: 210,
                      opacity: .46,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LiquidLight extends StatelessWidget {
  const _LiquidLight({
    required this.color,
    required this.widthFactor,
    required this.height,
    required this.opacity,
  });

  final Color color;
  final double widthFactor;
  final double height;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      heightFactor: 1,
      alignment: Alignment.topLeft,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: color.withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(120),
            ),
          ),
        ),
      ),
    );
  }
}
