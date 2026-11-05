import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:jp_auction_arena/core/constants/app_colors.dart';

class CricketBatBallAnimation extends StatefulWidget {
  final double size;

  const CricketBatBallAnimation({
    super.key,
    this.size = 180,
  });

  @override
  State<CricketBatBallAnimation> createState() => _CricketBatBallAnimationState();
}

class _CricketBatBallAnimationState extends State<CricketBatBallAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _batSwingAnimation;
  late Animation<double> _ballBounceAnimation;
  late Animation<double> _ballSpinAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // Bat swings back and forth like tapping crease then striking
    _batSwingAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.35, end: 0.15)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.15, end: 0.45)
            .chain(CurveTween(curve: Curves.fastOutSlowIn)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.45, end: -0.35)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_controller);

    // Ball bounces up and down to meet the bat
    _ballBounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 40.0, end: -35.0)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -35.0, end: 40.0)
            .chain(CurveTween(curve: Curves.bounceOut)),
        weight: 60,
      ),
    ]).animate(_controller);

    _ballSpinAnimation = Tween<double>(begin: 0.0, end: math.pi * 4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ambient pulse ring
              Container(
                width: widget.size * 0.9,
                height: widget.size * 0.9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondaryPurple
                          .withValues(alpha: 0.25 * _glowAnimation.value),
                      blurRadius: 36 * _glowAnimation.value,
                      spreadRadius: 8 * _glowAnimation.value,
                    ),
                    BoxShadow(
                      color: AppColors.accentPink
                          .withValues(alpha: 0.2 * _glowAnimation.value),
                      blurRadius: 48 * _glowAnimation.value,
                    ),
                  ],
                ),
              ),

              // Cricket Pitch / Base Glow Ring
              Container(
                width: widget.size * 0.75,
                height: widget.size * 0.75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.card.withValues(alpha: 0.7),
                  border: Border.all(
                    color: AppColors.primaryBlue.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
              ),

              // The Cricket Bat (CustomPainted wood texture with grip)
              Transform.translate(
                offset: const Offset(-8, -4),
                child: Transform.rotate(
                  angle: _batSwingAnimation.value,
                  alignment: Alignment.bottomRight,
                  child: CustomPaint(
                    size: Size(widget.size * 0.48, widget.size * 0.8),
                    painter: _CricketBatPainter(),
                  ),
                ),
              ),

              // The Cricket Leather Ball with Seam (Red / Gold stitched ball)
              Transform.translate(
                offset: Offset(32, _ballBounceAnimation.value),
                child: Transform.rotate(
                  angle: _ballSpinAnimation.value,
                  child: CustomPaint(
                    size: Size(widget.size * 0.28, widget.size * 0.28),
                    painter: _CricketBallPainter(),
                  ),
                ),
              ),

              // Impact Sparkles (visible at strike point)
              if (_batSwingAnimation.value > 0.1 && _batSwingAnimation.value < 0.4)
                Positioned(
                  right: widget.size * 0.32,
                  top: widget.size * 0.38,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentPink,
                          blurRadius: 16,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CricketBatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Bat Blade Gradient (English Willow / Modern Carbon Gold)
    final bladeRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + size.height * 0.12),
      width: size.width * 0.38,
      height: size.height * 0.62,
    );
    final bladeRRect = RRect.fromRectAndRadius(
      bladeRect,
      Radius.circular(size.width * 0.1),
    );

    final bladePaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFF6D365),
          Color(0xFFFDA085),
          Color(0xFFD97706),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bladeRect);

    // Shadow
    canvas.drawRRect(
      bladeRRect,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Blade body
    canvas.drawRRect(bladeRRect, bladePaint);

    // Blade center spine
    final spinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(bladeRect.center.dx, bladeRect.top + 6),
      Offset(bladeRect.center.dx, bladeRect.bottom - 6),
      spinePaint,
    );

    // Bat Handle / Rubber Grip (Purple / Pink spiral)
    final handleRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy - size.height * 0.30),
      width: size.width * 0.14,
      height: size.height * 0.30,
    );
    final handleRRect = RRect.fromRectAndRadius(
      handleRect,
      Radius.circular(size.width * 0.06),
    );

    final handlePaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF3B82F6),
          Color(0xFF8B5CF6),
          Color(0xFFEC4899),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(handleRect);

    canvas.drawRRect(handleRRect, handlePaint);

    // Rubber grip ribs
    final ribPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..strokeWidth = 1.6;
    for (int i = 0; i < 5; i++) {
      final y = handleRect.top + (i + 1) * (handleRect.height / 6);
      canvas.drawLine(
        Offset(handleRect.left + 1, y),
        Offset(handleRect.right - 1, y),
        ribPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _CricketBallPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Glowing ball shadow
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.statusLive.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Cherry Red Leather Cricket Ball
    final ballPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 0.85,
        colors: const [
          Color(0xFFFF5252),
          Color(0xFFD50000),
          Color(0xFF8B0000),
          Color(0xFF3E0000),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, ballPaint);

    // Ball White Raised Seam
    final seamPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    final seamPath = Path();
    seamPath.moveTo(center.dx - radius * 0.85, center.dy);
    seamPath.quadraticBezierTo(
      center.dx,
      center.dy + radius * 0.35,
      center.dx + radius * 0.85,
      center.dy,
    );
    canvas.drawPath(seamPath, seamPaint);

    // Seam Stitches (crosses)
    final stitchPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..strokeWidth = 1.2;
    for (int i = -3; i <= 3; i++) {
      final x = center.dx + (i * radius * 0.22);
      final y = center.dy + (radius * 0.12 * (1 - (i.abs() / 4.0)));
      canvas.drawLine(
        Offset(x - 2, y - 3),
        Offset(x + 2, y + 3),
        stitchPaint,
      );
    }

    // Specular highlight on leather
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(
      Offset(center.dx - radius * 0.35, center.dy - radius * 0.35),
      radius * 0.22,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
