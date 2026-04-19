import 'package:flutter/material.dart';
import '../services/profile_service.dart';

/// Cute minimalist cartoon avatar widget
class CartoonAvatar extends StatelessWidget {
  final AvatarType type;
  final double size;
  final bool showBorder;
  final Color? borderColor;

  const CartoonAvatar({
    super.key,
    required this.type,
    this.size = 100,
    this.showBorder = true,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: showBorder
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: borderColor ?? Colors.white,
                width: size * 0.03,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            )
          : null,
      child: ClipOval(
        child: CustomPaint(
          size: Size(size, size),
          painter: _CuteAvatarPainter(avatarType: type),
        ),
      ),
    );
  }
}

class _CuteAvatarPainter extends CustomPainter {
  final AvatarType avatarType;

  _CuteAvatarPainter({required this.avatarType});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = avatarType == AvatarType.neutral
          ? const Color(0xFFE0E0E0)
          : const Color(0xFFFFF3E6);
    canvas.drawCircle(center, radius, bgPaint);

    switch (avatarType) {
      case AvatarType.neutral:
        _drawBlankSilhouette(canvas, size, center, radius);
      case AvatarType.male:
        _drawMaleAvatar(canvas, size, center, radius);
      case AvatarType.female:
        _drawFemaleAvatar(canvas, size, center, radius);
    }
  }

  void _drawBlankSilhouette(Canvas canvas, Size size, Offset center, double radius) {
    final silhouettePaint = Paint()
      ..color = const Color(0xFFBDBDBD)
      ..style = PaintingStyle.fill;

    // Head circle
    final headRadius = radius * 0.28;
    final headCenter = Offset(center.dx, center.dy - radius * 0.15);
    canvas.drawCircle(headCenter, headRadius, silhouettePaint);

    // Body/shoulders arc
    final bodyPath = Path();
    final shoulderWidth = radius * 0.7;
    final bodyTop = headCenter.dy + headRadius + radius * 0.08;

    bodyPath.moveTo(center.dx - shoulderWidth, center.dy + radius);
    bodyPath.quadraticBezierTo(
      center.dx - shoulderWidth,
      bodyTop,
      center.dx,
      bodyTop,
    );
    bodyPath.quadraticBezierTo(
      center.dx + shoulderWidth,
      bodyTop,
      center.dx + shoulderWidth,
      center.dy + radius,
    );
    bodyPath.close();

    canvas.drawPath(bodyPath, silhouettePaint);
  }

  void _drawMaleAvatar(Canvas canvas, Size size, Offset center, double radius) {
    // Face
    final facePaint = Paint()..color = const Color(0xFFFFE4C9);
    final faceRadius = radius * 0.48;
    final faceCenter = Offset(center.dx, center.dy + radius * 0.05);
    canvas.drawCircle(faceCenter, faceRadius, facePaint);

    // Ears
    final earPaint = Paint()..color = const Color(0xFFFFD9B8);
    final earRadius = faceRadius * 0.18;
    canvas.drawCircle(
      Offset(faceCenter.dx - faceRadius * 0.92, faceCenter.dy),
      earRadius,
      earPaint,
    );
    canvas.drawCircle(
      Offset(faceCenter.dx + faceRadius * 0.92, faceCenter.dy),
      earRadius,
      earPaint,
    );

    // Hair - short messy black hair
    final hairPaint = Paint()..color = const Color(0xFF2D2D2D);

    final hairPath = Path();
    final hairTop = faceCenter.dy - faceRadius * 0.95;
    final hairLeft = faceCenter.dx - faceRadius * 0.85;
    final hairRight = faceCenter.dx + faceRadius * 0.85;

    hairPath.moveTo(hairLeft, faceCenter.dy - faceRadius * 0.3);
    hairPath.quadraticBezierTo(
      hairLeft - faceRadius * 0.1,
      hairTop + faceRadius * 0.3,
      faceCenter.dx - faceRadius * 0.5,
      hairTop,
    );

    // Messy spikes on top
    hairPath.lineTo(faceCenter.dx - faceRadius * 0.35, hairTop - faceRadius * 0.15);
    hairPath.lineTo(faceCenter.dx - faceRadius * 0.15, hairTop + faceRadius * 0.05);
    hairPath.lineTo(faceCenter.dx, hairTop - faceRadius * 0.12);
    hairPath.lineTo(faceCenter.dx + faceRadius * 0.2, hairTop + faceRadius * 0.02);
    hairPath.lineTo(faceCenter.dx + faceRadius * 0.4, hairTop - faceRadius * 0.1);
    hairPath.lineTo(faceCenter.dx + faceRadius * 0.55, hairTop + faceRadius * 0.05);

    hairPath.quadraticBezierTo(
      hairRight + faceRadius * 0.1,
      hairTop + faceRadius * 0.3,
      hairRight,
      faceCenter.dy - faceRadius * 0.3,
    );

    // Side hair
    hairPath.quadraticBezierTo(
      hairRight + faceRadius * 0.05,
      faceCenter.dy - faceRadius * 0.1,
      hairRight - faceRadius * 0.1,
      faceCenter.dy - faceRadius * 0.05,
    );

    hairPath.lineTo(hairLeft + faceRadius * 0.1, faceCenter.dy - faceRadius * 0.05);

    hairPath.quadraticBezierTo(
      hairLeft - faceRadius * 0.05,
      faceCenter.dy - faceRadius * 0.1,
      hairLeft,
      faceCenter.dy - faceRadius * 0.3,
    );

    hairPath.close();
    canvas.drawPath(hairPath, hairPaint);

    // Eyes - simple dots
    final eyePaint = Paint()..color = const Color(0xFF2D2D2D);
    final eyeRadius = faceRadius * 0.08;
    final eyeY = faceCenter.dy - faceRadius * 0.05;
    canvas.drawCircle(
      Offset(faceCenter.dx - faceRadius * 0.28, eyeY),
      eyeRadius,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(faceCenter.dx + faceRadius * 0.28, eyeY),
      eyeRadius,
      eyePaint,
    );

    // Rosy cheeks
    final cheekPaint = Paint()..color = const Color(0xFFFFB5B5).withAlpha(150);
    final cheekRadius = faceRadius * 0.14;
    final cheekY = faceCenter.dy + faceRadius * 0.18;
    canvas.drawCircle(
      Offset(faceCenter.dx - faceRadius * 0.42, cheekY),
      cheekRadius,
      cheekPaint,
    );
    canvas.drawCircle(
      Offset(faceCenter.dx + faceRadius * 0.42, cheekY),
      cheekRadius,
      cheekPaint,
    );

    // Simple smile
    final smilePaint = Paint()
      ..color = const Color(0xFF2D2D2D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = faceRadius * 0.06
      ..strokeCap = StrokeCap.round;

    final smilePath = Path();
    smilePath.moveTo(faceCenter.dx - faceRadius * 0.15, faceCenter.dy + faceRadius * 0.32);
    smilePath.quadraticBezierTo(
      faceCenter.dx,
      faceCenter.dy + faceRadius * 0.45,
      faceCenter.dx + faceRadius * 0.15,
      faceCenter.dy + faceRadius * 0.32,
    );
    canvas.drawPath(smilePath, smilePaint);
  }

  void _drawFemaleAvatar(Canvas canvas, Size size, Offset center, double radius) {
    // Hair background - long wavy black hair
    final hairPaint = Paint()..color = const Color(0xFF2D2D2D);

    // Draw hair behind face first
    final hairBgPath = Path();
    final hairTop = center.dy - radius * 0.65;

    hairBgPath.moveTo(center.dx - radius * 0.7, center.dy + radius * 0.7);
    hairBgPath.quadraticBezierTo(
      center.dx - radius * 0.85,
      center.dy,
      center.dx - radius * 0.75,
      hairTop + radius * 0.2,
    );
    hairBgPath.quadraticBezierTo(
      center.dx - radius * 0.5,
      hairTop - radius * 0.1,
      center.dx,
      hairTop,
    );
    hairBgPath.quadraticBezierTo(
      center.dx + radius * 0.5,
      hairTop - radius * 0.1,
      center.dx + radius * 0.75,
      hairTop + radius * 0.2,
    );
    hairBgPath.quadraticBezierTo(
      center.dx + radius * 0.85,
      center.dy,
      center.dx + radius * 0.7,
      center.dy + radius * 0.7,
    );

    // Wavy bottom with curves
    hairBgPath.quadraticBezierTo(
      center.dx + radius * 0.5,
      center.dy + radius * 0.85,
      center.dx + radius * 0.35,
      center.dy + radius * 0.75,
    );
    hairBgPath.quadraticBezierTo(
      center.dx + radius * 0.15,
      center.dy + radius * 0.9,
      center.dx,
      center.dy + radius * 0.78,
    );
    hairBgPath.quadraticBezierTo(
      center.dx - radius * 0.15,
      center.dy + radius * 0.9,
      center.dx - radius * 0.35,
      center.dy + radius * 0.75,
    );
    hairBgPath.quadraticBezierTo(
      center.dx - radius * 0.5,
      center.dy + radius * 0.85,
      center.dx - radius * 0.7,
      center.dy + radius * 0.7,
    );

    hairBgPath.close();
    canvas.drawPath(hairBgPath, hairPaint);

    // Face
    final facePaint = Paint()..color = const Color(0xFFFFE4C9);
    final faceRadius = radius * 0.45;
    final faceCenter = Offset(center.dx, center.dy + radius * 0.05);
    canvas.drawCircle(faceCenter, faceRadius, facePaint);

    // Ears (partially hidden by hair)
    final earPaint = Paint()..color = const Color(0xFFFFD9B8);
    final earRadius = faceRadius * 0.15;
    canvas.drawCircle(
      Offset(faceCenter.dx - faceRadius * 0.88, faceCenter.dy - faceRadius * 0.05),
      earRadius,
      earPaint,
    );
    canvas.drawCircle(
      Offset(faceCenter.dx + faceRadius * 0.88, faceCenter.dy - faceRadius * 0.05),
      earRadius,
      earPaint,
    );

    // Bangs
    final bangsPath = Path();
    final bangsTop = faceCenter.dy - faceRadius * 0.85;

    // Left side bangs
    bangsPath.moveTo(faceCenter.dx - faceRadius * 0.9, faceCenter.dy - faceRadius * 0.15);
    bangsPath.quadraticBezierTo(
      faceCenter.dx - faceRadius * 0.95,
      bangsTop + faceRadius * 0.2,
      faceCenter.dx - faceRadius * 0.6,
      bangsTop,
    );
    bangsPath.lineTo(faceCenter.dx - faceRadius * 0.45, faceCenter.dy - faceRadius * 0.35);
    bangsPath.lineTo(faceCenter.dx - faceRadius * 0.25, bangsTop + faceRadius * 0.05);
    bangsPath.lineTo(faceCenter.dx, faceCenter.dy - faceRadius * 0.3);
    bangsPath.lineTo(faceCenter.dx + faceRadius * 0.25, bangsTop + faceRadius * 0.05);
    bangsPath.lineTo(faceCenter.dx + faceRadius * 0.45, faceCenter.dy - faceRadius * 0.35);
    bangsPath.lineTo(faceCenter.dx + faceRadius * 0.6, bangsTop);
    bangsPath.quadraticBezierTo(
      faceCenter.dx + faceRadius * 0.95,
      bangsTop + faceRadius * 0.2,
      faceCenter.dx + faceRadius * 0.9,
      faceCenter.dy - faceRadius * 0.15,
    );

    // Top of head arc
    bangsPath.quadraticBezierTo(
      faceCenter.dx + faceRadius * 0.5,
      bangsTop - faceRadius * 0.3,
      faceCenter.dx,
      bangsTop - faceRadius * 0.25,
    );
    bangsPath.quadraticBezierTo(
      faceCenter.dx - faceRadius * 0.5,
      bangsTop - faceRadius * 0.3,
      faceCenter.dx - faceRadius * 0.9,
      faceCenter.dy - faceRadius * 0.15,
    );

    bangsPath.close();
    canvas.drawPath(bangsPath, hairPaint);

    // Side hair strands over ears
    final leftStrandPath = Path();
    leftStrandPath.moveTo(faceCenter.dx - faceRadius * 0.85, faceCenter.dy - faceRadius * 0.2);
    leftStrandPath.quadraticBezierTo(
      faceCenter.dx - faceRadius * 1.0,
      faceCenter.dy + faceRadius * 0.3,
      faceCenter.dx - faceRadius * 0.75,
      faceCenter.dy + faceRadius * 0.6,
    );
    leftStrandPath.lineTo(faceCenter.dx - faceRadius * 0.65, faceCenter.dy + faceRadius * 0.5);
    leftStrandPath.quadraticBezierTo(
      faceCenter.dx - faceRadius * 0.75,
      faceCenter.dy + faceRadius * 0.2,
      faceCenter.dx - faceRadius * 0.7,
      faceCenter.dy - faceRadius * 0.1,
    );
    leftStrandPath.close();
    canvas.drawPath(leftStrandPath, hairPaint);

    final rightStrandPath = Path();
    rightStrandPath.moveTo(faceCenter.dx + faceRadius * 0.85, faceCenter.dy - faceRadius * 0.2);
    rightStrandPath.quadraticBezierTo(
      faceCenter.dx + faceRadius * 1.0,
      faceCenter.dy + faceRadius * 0.3,
      faceCenter.dx + faceRadius * 0.75,
      faceCenter.dy + faceRadius * 0.6,
    );
    rightStrandPath.lineTo(faceCenter.dx + faceRadius * 0.65, faceCenter.dy + faceRadius * 0.5);
    rightStrandPath.quadraticBezierTo(
      faceCenter.dx + faceRadius * 0.75,
      faceCenter.dy + faceRadius * 0.2,
      faceCenter.dx + faceRadius * 0.7,
      faceCenter.dy - faceRadius * 0.1,
    );
    rightStrandPath.close();
    canvas.drawPath(rightStrandPath, hairPaint);

    // Eyes - simple dots
    final eyePaint = Paint()..color = const Color(0xFF2D2D2D);
    final eyeRadius = faceRadius * 0.08;
    final eyeY = faceCenter.dy - faceRadius * 0.02;
    canvas.drawCircle(
      Offset(faceCenter.dx - faceRadius * 0.28, eyeY),
      eyeRadius,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(faceCenter.dx + faceRadius * 0.28, eyeY),
      eyeRadius,
      eyePaint,
    );

    // Rosy cheeks
    final cheekPaint = Paint()..color = const Color(0xFFFFB5B5).withAlpha(150);
    final cheekRadius = faceRadius * 0.14;
    final cheekY = faceCenter.dy + faceRadius * 0.2;
    canvas.drawCircle(
      Offset(faceCenter.dx - faceRadius * 0.4, cheekY),
      cheekRadius,
      cheekPaint,
    );
    canvas.drawCircle(
      Offset(faceCenter.dx + faceRadius * 0.4, cheekY),
      cheekRadius,
      cheekPaint,
    );

    // Simple smile
    final smilePaint = Paint()
      ..color = const Color(0xFF2D2D2D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = faceRadius * 0.06
      ..strokeCap = StrokeCap.round;

    final smilePath = Path();
    smilePath.moveTo(faceCenter.dx - faceRadius * 0.15, faceCenter.dy + faceRadius * 0.35);
    smilePath.quadraticBezierTo(
      faceCenter.dx,
      faceCenter.dy + faceRadius * 0.48,
      faceCenter.dx + faceRadius * 0.15,
      faceCenter.dy + faceRadius * 0.35,
    );
    canvas.drawPath(smilePath, smilePaint);
  }

  @override
  bool shouldRepaint(covariant _CuteAvatarPainter oldDelegate) {
    return oldDelegate.avatarType != avatarType;
  }
}
