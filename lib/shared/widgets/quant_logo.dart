import '../../core/localization/app_strings.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'quant_mark_path.dart';

class QuantLogo extends StatelessWidget {
  const QuantLogo({this.size = 44, super.key});
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
      label: context.tr('Логотип quant: плавная открытая q'),
      image: true,
      child: SizedBox.square(
          dimension: size,
          child: const CustomPaint(painter: QuantLogoPainter())));
}

class QuantLogoPainter extends CustomPainter {
  const QuantLogoPainter();
  static final Path _mark = createQuantMarkPath();
  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / 108;
    canvas.save();
    canvas.translate(
        (size.width - 108 * scale) / 2, (size.height - 108 * scale) / 2);
    canvas.scale(scale);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(0, 0, 108, 108), const Radius.circular(26)),
        Paint()..color = const Color(0xFF121212));
    canvas.drawPath(_mark, Paint()..color = const Color(0xFFB4A0E5));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant QuantLogoPainter oldDelegate) => false;
}
