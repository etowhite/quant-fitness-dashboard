import '../../core/localization/app_strings.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class QuantLogo extends StatelessWidget {
  const QuantLogo({this.size = 44, super.key});
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
      label: context.tr('Логотип quant: кольца активности в форме q'),
      image: true,
      child: SizedBox.square(
          dimension: size,
          child: const CustomPaint(painter: QuantLogoPainter())));
}

class QuantLogoPainter extends CustomPainter {
  const QuantLogoPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / 108;
    canvas.save();
    canvas.scale(scale);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(0, 0, 108, 108), const Radius.circular(28)),
        Paint()..color = const Color(0xFF121212));
    const colors = [Color(0xFF00FF87), Color(0xFF00E5FF), Color(0xFF8B5CF6)];
    for (var i = 0; i < 3; i++) {
      final radius = 33.0 - i * 10;
      final rect =
          Rect.fromCircle(center: const Offset(51, 51), radius: radius);
      canvas.drawCircle(
          const Offset(51, 51),
          radius,
          Paint()
            ..color = colors[i].withAlpha(28)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7.5);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7.5
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
                colors: [
              colors[i].withAlpha(100),
              colors[i],
              Color.lerp(colors[i], Colors.white, .22)!
            ],
                startAngle: -math.pi / 2,
                endAngle: math.pi * 1.5,
                transform: const GradientRotation(-math.pi / 2))
            .createShader(rect);
      canvas.drawArc(
          rect,
          -math.pi / 2,
          math.pi *
              (i == 0
                  ? 1.8
                  : i == 1
                      ? 1.55
                      : 1.3),
          false,
          paint);
    }
    canvas.drawLine(
        const Offset(73, 76),
        const Offset(88, 91),
        Paint()
          ..color = colors.first
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant QuantLogoPainter oldDelegate) => false;
}
