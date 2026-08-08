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

    final noteHeadPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final stemPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale
      ..strokeCap = StrokeCap.round;

    // Draw left note head
    canvas.save();
    canvas.translate(9.5 * scale, 15.5 * scale);
    canvas.rotate(-0.25);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: 3.5 * scale,
        height: 2.6 * scale,
      ),
      noteHeadPaint,
    );
    canvas.restore();

    // Draw right note head
    canvas.save();
    canvas.translate(14.5 * scale, 14.5 * scale);
    canvas.rotate(-0.25);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: 3.5 * scale,
        height: 2.6 * scale,
      ),
      noteHeadPaint,
    );
    canvas.restore();

    // Draw stems
    canvas.drawLine(
      Offset(11.0 * scale, 15.5 * scale),
      Offset(11.0 * scale, 9.5 * scale),
      stemPaint,
    );
    canvas.drawLine(
      Offset(16.0 * scale, 14.5 * scale),
      Offset(16.0 * scale, 8.5 * scale),
      stemPaint,
    );

    // Draw beam (connecting tops of stems)
    final beamPath = Path()
      ..moveTo(10.25 * scale, 10.0 * scale)
      ..lineTo(16.75 * scale, 8.7 * scale)
      ..lineTo(16.75 * scale, 10.7 * scale)
      ..lineTo(10.25 * scale, 12.0 * scale)
      ..close();
    canvas.drawPath(beamPath, noteHeadPaint);
  }

  @override
  bool shouldRepaint(_MeloLocalMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}
