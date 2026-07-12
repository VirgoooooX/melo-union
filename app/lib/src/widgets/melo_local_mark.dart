import 'package:flutter/material.dart';

import '../design/melo_tokens.dart';

class MeloLocalMark extends StatelessWidget {
  const MeloLocalMark({this.size = 24, this.color, super.key});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _MeloLocalMarkPainter(color ?? MeloColors.localForeground),
      );
}

final class _MeloLocalMarkPainter extends CustomPainter {
  const _MeloLocalMarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color.withValues(alpha: .12)
      ..style = PaintingStyle.fill;
    final body = Path()
      ..moveTo(3 * scale, 8 * scale)
      ..quadraticBezierTo(3 * scale, 6 * scale, 5 * scale, 6 * scale)
      ..lineTo(9 * scale, 6 * scale)
      ..lineTo(11 * scale, 3.8 * scale)
      ..lineTo(19 * scale, 3.8 * scale)
      ..quadraticBezierTo(21 * scale, 3.8 * scale, 21 * scale, 5.8 * scale)
      ..lineTo(21 * scale, 18.5 * scale)
      ..quadraticBezierTo(21 * scale, 20.5 * scale, 19 * scale, 20.5 * scale)
      ..lineTo(5 * scale, 20.5 * scale)
      ..quadraticBezierTo(3 * scale, 20.5 * scale, 3 * scale, 18.5 * scale)
      ..close();
    canvas.drawPath(body, fill);
    canvas.drawPath(body, stroke);
    canvas.drawCircle(Offset(12 * scale, 13 * scale), 4.2 * scale, stroke);
    canvas.drawCircle(Offset(12 * scale, 13 * scale), 1.05 * scale, stroke);
  }

  @override
  bool shouldRepaint(_MeloLocalMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}
