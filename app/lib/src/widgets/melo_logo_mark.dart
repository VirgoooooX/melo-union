import 'package:flutter/material.dart';

class MeloLogoMark extends StatelessWidget {
  const MeloLogoMark({
    super.key,
    this.size = 32,
    this.semanticLabel = 'MeloUnion logo',
  });

  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final logo = SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: const _MeloLogoMarkPainter()),
    );

    if (semanticLabel == null) return logo;
    return Semantics(
      image: true,
      label: semanticLabel,
      child: ExcludeSemantics(child: logo),
    );
  }
}

class _MeloLogoMarkPainter extends CustomPainter {
  const _MeloLogoMarkPainter();

  static const _viewBox = Rect.fromLTWH(45, -0.5, 291, 291);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / _viewBox.width;
    final dx = (size.width - _viewBox.width * scale) / 2;
    final dy = (size.height - _viewBox.height * scale) / 2;

    canvas
      ..save()
      ..translate(dx, dy)
      ..scale(scale)
      ..translate(-_viewBox.left, -_viewBox.top);

    _drawSideBars(canvas);
    _drawMainMark(canvas);

    canvas.restore();
  }

  void _drawSideBars(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(58, 111, 21, 58.5),
        const Radius.circular(10.5),
      ),
      _gradientPaint(
        const Offset(68, 111),
        const Offset(68, 169),
        const [Color(0xFFB8E2DE), Color(0xFFA1D4CF)],
      ),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(97, 84, 22, 112),
        const Radius.circular(11),
      ),
      _gradientPaint(
        const Offset(108, 84),
        const Offset(108, 196),
        const [Color(0xFF67C0B9), Color(0xFF45A9A1)],
      ),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(262.5, 84, 22, 112),
        const Radius.circular(11),
      ),
      _gradientPaint(
        const Offset(273, 84),
        const Offset(273, 196),
        const [Color(0xFF69C2BA), Color(0xFF49AAA3)],
      ),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(302, 111, 21, 58.5),
        const Radius.circular(10.5),
      ),
      _gradientPaint(
        const Offset(313, 111),
        const Offset(313, 169),
        const [Color(0xFFB8E2DE), Color(0xFFA2D5D0)],
      ),
    );
  }

  void _drawMainMark(Canvas canvas) {
    final leftMain = Path()
      ..moveTo(149.25, 51)
      ..cubicTo(156.3, 51, 162, 56.7, 162, 63.75)
      ..lineTo(162, 178.6)
      ..cubicTo(162, 187.2, 156.4, 193.7, 151.8, 203.6)
      ..cubicTo(148.3, 211.1, 149.3, 221.6, 155.35, 228.55)
      ..cubicTo(143, 222.3, 136.5, 209.2, 136.5, 192.2)
      ..lineTo(136.5, 63.75)
      ..cubicTo(136.5, 56.7, 142.2, 51, 149.25, 51)
      ..close();

    final crescentCut = Path()
      ..moveTo(153.8, 229.4)
      ..cubicTo(143.2, 216.5, 144.6, 197.2, 156.2, 184.1)
      ..cubicTo(167.1, 171.9, 184.1, 167.8, 199.6, 174.8)
      ..cubicTo(181.6, 180.1, 170, 192.3, 170, 207.2)
      ..cubicTo(170, 219.5, 178.2, 228.8, 190.4, 233.2)
      ..cubicTo(176.4, 235, 163.7, 233.6, 153.8, 229.4)
      ..close();

    canvas.drawPath(
      Path.combine(PathOperation.difference, leftMain, crescentCut),
      _gradientPaint(
        const Offset(148, 51),
        const Offset(155, 229),
        const [
          Color(0xFF09988D),
          Color(0xFF078B83),
          Color(0xFF009086),
        ],
        const [0, .48, 1],
      ),
    );

    final rightNote = Path()
      ..moveTo(232.75, 51)
      ..cubicTo(239.8, 51, 245.5, 56.7, 245.5, 63.75)
      ..lineTo(245.5, 194.3)
      ..cubicTo(245.5, 219.35, 225.3, 239, 200.4, 239)
      ..cubicTo(175.2, 239, 156.5, 225.5, 156.5, 206.5)
      ..cubicTo(156.5, 187.8, 173.7, 174, 196.1, 174)
      ..cubicTo(206.2, 174, 214.7, 177.2, 220, 183.1)
      ..lineTo(220, 63.75)
      ..cubicTo(220, 56.7, 225.7, 51, 232.75, 51)
      ..close();

    canvas.drawPath(
      rightNote,
      _gradientPaint(
        const Offset(232, 51),
        const Offset(201, 239),
        const [
          Color(0xFF09968C),
          Color(0xFF078980),
          Color(0xFF009187),
        ],
        const [0, .52, 1],
      ),
    );
  }

  Paint _gradientPaint(
    Offset from,
    Offset to,
    List<Color> colors, [
    List<double>? stops,
  ]) {
    final left = from.dx < to.dx ? from.dx : to.dx;
    final right = from.dx > to.dx ? from.dx : to.dx;
    final top = from.dy < to.dy ? from.dy : to.dy;
    final bottom = from.dy > to.dy ? from.dy : to.dy;
    final shaderRect = Rect.fromLTRB(left - 1, top, right + 1, bottom);
    return Paint()
      ..isAntiAlias = true
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
        stops: stops,
      ).createShader(shaderRect);
  }

  @override
  bool shouldRepaint(covariant _MeloLogoMarkPainter oldDelegate) => false;
}
