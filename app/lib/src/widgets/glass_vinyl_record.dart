import 'dart:math' show Random;

import 'package:flutter/material.dart';

/// ── 深海蓝玻璃黑胶唱片组件 ──
///
/// 通过多层 Flutter Widget / CustomPainter / 渐变 / 透明度 叠绘，
/// 呈现介于黑胶、半透明磨砂玻璃、深蓝亚克力之间的材质质感。
///
/// 视觉层次（从底到顶）：
///   1. 外圈蓝色扩散辉光（_BackGlowPainter）
///   2. 深色背景星点（_StarFieldPainter）
///   3. 旋转唱片主体（RadialGradient + SweepGradient + 同心刻纹 + 专辑封面）
///   4. 斜向银灰镜面高光（ClipOval + Transform.rotate + LinearGradient）
///   5. 不完整青蓝边缘发光弧线（_EdgeArcPainter）
///   6. 唱片中心轴点
///
/// 所有颜色、透明度、半径、动画速度均抽为可配参数。
// ============================================================================
//  颜色常量
// ============================================================================
const Color _deepNavy = Color(0xFF031B3A);
const Color _vinylBlue = Color(0xFF0A315C);
const Color _grooveBlue = Color(0xFF6D93B6);
const Color _edgeCyan = Color(0xFF3EE7E1);
const Color _edgeTeal = Color(0xFF0DB6B2);
const Color _mistBlue = Color(0xFF1E79BA);

// ============================================================================
//  GlassVinylRecord
// ============================================================================
class GlassVinylRecord extends StatefulWidget {
  const GlassVinylRecord({
    super.key,
    /// 嵌入唱片中央的专辑封面 widget（外部构建，组件用 ClipOval 裁圆）。
    /// 传 null 则仅显示深色唱片本体，不展示封面区域。
    this.artwork,
    /// 是否正在播放。`true` 时唱片持续旋转，`false` 时停止。
    required this.isPlaying,
    /// 唱片直径（不含外圈辉光的 padding）。
    this.size = 310,
    /// 同心刻纹数量，建议 12–18。
    this.grooveCount = 16,
    /// 唱片主体透明度，`1.0` = 完全不透明。
    this.discOpacity = 0.88,
    /// 外圈辉光强度倍率，`1.0` = 全强度。
    this.glowOpacity = 0.45,
    /// 唱片完整旋转一圈的时长。
    this.rotationDuration = const Duration(seconds: 22),
    /// 镜面高光的旋转弧度（控制高光倾斜角度）。
    this.highlightAngle = -0.55,
    /// 镜面高光最高不透明度。
    this.highlightOpacity = 0.20,
    /// 边缘发光弧线起始弧度（Flutter 坐标系：0 = 3 点钟方向）。
    this.arcStartAngle = -2.55,
    /// 边缘发光弧线扫过的弧度。
    this.arcSweepAngle = 1.15,
  });

  final Widget? artwork;
  final bool isPlaying;
  final double size;
  final int grooveCount;
  final double discOpacity;
  final double glowOpacity;
  final Duration rotationDuration;
  final double highlightAngle;
  final double highlightOpacity;
  final double arcStartAngle;
  final double arcSweepAngle;

  @override
  State<GlassVinylRecord> createState() => _GlassVinylRecordState();
}

class _GlassVinylRecordState extends State<GlassVinylRecord>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.rotationDuration,
    );
    if (widget.isPlaying) _controller.repeat();
  }

  @override
  void didUpdateWidget(GlassVinylRecord oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying && !_controller.isAnimating) {
        _controller.repeat();
      } else if (!widget.isPlaying && _controller.isAnimating) {
        _controller.stop();
      }
    }
    if (widget.rotationDuration != oldWidget.rotationDuration) {
      _controller.duration = widget.rotationDuration;
      if (_controller.isAnimating) _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 唱片外圈辉光额外占位，避免被父级裁切
  static const double _glowPad = 14;

  @override
  Widget build(BuildContext context) {
    final d = widget.size;
    final total = d + _glowPad * 2;

    return SizedBox(
      width: total,
      height: total,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── 1. 外圈蓝色扩散辉光 ──
          Positioned.fill(
            child: CustomPaint(
              painter: _BackGlowPainter(
                discRadius: d / 2,
                glowOpacity: widget.glowOpacity,
              ),
            ),
          ),

          // ── 2. 星点背景 ──
          Positioned.fill(
            child: CustomPaint(
              painter: _StarFieldPainter(seed: d.toInt()),
            ),
          ),

          // ── 3. 旋转唱片主体（含刻纹、封面、轴点）──
          Positioned(
            left: _glowPad,
            top: _glowPad,
            child: SizedBox(
              width: d,
              height: d,
              child: RotationTransition(
                turns: _controller,
                child: RepaintBoundary(
                  child: Stack(
                    children: [
                      // 唱片盘面 + 刻纹
                      CustomPaint(
                        painter: _GlassVinylDiscPainter(
                          grooveCount: widget.grooveCount,
                          discOpacity: widget.discOpacity,
                        ),
                        child: Center(
                          child: ClipOval(
                            child: SizedBox(
                              width: d * 0.57,
                              height: d * 0.57,
                              child: widget.artwork,
                            ),
                          ),
                        ),
                      ),
                      // 中心轴点
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Center(
                            child: Container(
                              width: d * 0.038,
                              height: d * 0.038,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const RadialGradient(
                                  colors: [
                                    Color(0xE0FFFFFF),
                                    Color(0x88FFFFFF),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: .26),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── 4. 镜面高光（斜向银灰半透明，不旋转）──
          Positioned(
            left: _glowPad,
            top: _glowPad,
            child: ClipOval(
              child: SizedBox(
                width: d,
                height: d,
                child: Transform.rotate(
                  angle: widget.highlightAngle,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.white
                              .withValues(alpha: widget.highlightOpacity * .30),
                          Colors.white
                              .withValues(alpha: widget.highlightOpacity),
                          Colors.white
                              .withValues(alpha: widget.highlightOpacity * .30),
                          Colors.transparent,
                        ],
                        stops: const [0, .36, .48, .56, 1],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── 5. 不完整青蓝边缘发光弧线 ──
          Positioned.fill(
            child: CustomPaint(
              painter: _EdgeArcPainter(
                discRadius: d / 2,
                glowOpacity: widget.glowOpacity,
                arcStartAngle: widget.arcStartAngle,
                arcSweepAngle: widget.arcSweepAngle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
//  Painter: 外圈蓝色扩散辉光
// ============================================================================
class _BackGlowPainter extends CustomPainter {
  const _BackGlowPainter({
    required this.discRadius,
    required this.glowOpacity,
  });

  final double discRadius;
  final double glowOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 大范围蓝色雾光
    final fogRadius = discRadius * 1.22;
    final fog = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, .08),
        radius: .92,
        colors: [
          _mistBlue.withValues(alpha: .14 * glowOpacity),
          _mistBlue.withValues(alpha: .06 * glowOpacity),
          Colors.transparent,
        ],
        stops: const [0, .58, 1],
      ).createShader(Rect.fromCircle(center: center, radius: fogRadius));
    canvas.drawCircle(center, fogRadius, fog);

    // 紧贴唱片的微弱 Sweep 辉光环
    final sweepHalo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          _edgeCyan.withValues(alpha: .08 * glowOpacity),
          _edgeTeal.withValues(alpha: .04 * glowOpacity),
          Colors.transparent,
        ],
        stops: const [0, .14, .30, .44],
      ).createShader(Rect.fromCircle(center: center, radius: discRadius + 4));
    canvas.drawCircle(center, discRadius + 4, sweepHalo);
  }

  @override
  bool shouldRepaint(covariant _BackGlowPainter old) =>
      old.discRadius != discRadius || old.glowOpacity != glowOpacity;
}

// ============================================================================
//  Painter: 星点背景
// ============================================================================
class _StarFieldPainter extends CustomPainter {
  const _StarFieldPainter({required this.seed});
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(seed);
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < 28; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final radius = .3 + rng.nextDouble() * 1.0;
      final opacity = .04 + rng.nextDouble() * .32;
      paint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarFieldPainter old) => old.seed != seed;
}

// ============================================================================
//  Painter: 唱片盘面 + 同心刻纹
// ============================================================================
class _GlassVinylDiscPainter extends CustomPainter {
  const _GlassVinylDiscPainter({
    required this.grooveCount,
    required this.discOpacity,
  });

  final int grooveCount;
  final double discOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // ── 唱片径向渐变 ──
    final body = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-.16, -.18),
        radius: .84,
        colors: [
          _vinylBlue.withValues(alpha: discOpacity),
          const Color(0xFF0A203E).withValues(alpha: discOpacity),
          _deepNavy.withValues(alpha: discOpacity),
        ],
        stops: const [0, .52, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, body);

    // ── Sweep 边缘明暗变化 ──
    final sheen = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: .10),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0, .14, .28],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, sheen);

    // ── 同心刻纹 ──
    final groove = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final innerR = radius * .305; // 内圈起点（避开封面区域）
    final outerR = radius * .94; // 外圈终点
    final step = outerR - innerR;
    final count = grooveCount.clamp(6, 30);

    for (var i = 0; i < count; i++) {
      final r = innerR + step * i / (count - 1);
      // 线宽差异：0.4 ~ 1.2，避免机械感
      groove.strokeWidth = .4 + (i % 3) * .28;

      // 透明度在 8%–22% 之间波动
      final t = i / (count - 1);
      final alpha = .06 + t * .14 + (i % 5) * .008;
      groove.color = i.isEven
          ? _grooveBlue.withValues(alpha: alpha.clamp(0, .22))
          : const Color(0xFF4A7A9E)
              .withValues(alpha: (alpha * .78).clamp(0, .18));

      canvas.drawCircle(center, r, groove);
    }

    // ── 外圈细描边 ──
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: .10);
    canvas.drawCircle(center, radius - .5, rim);

    // ── 封面区域外框 ──
    final artBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .6
      ..color = Colors.white.withValues(alpha: .06);
    canvas.drawCircle(center, radius * .287, artBorder);
  }

  @override
  bool shouldRepaint(covariant _GlassVinylDiscPainter old) =>
      old.grooveCount != grooveCount || old.discOpacity != discOpacity;
}

// ============================================================================
//  Painter: 不完整青蓝边缘发光弧线
// ============================================================================
class _EdgeArcPainter extends CustomPainter {
  const _EdgeArcPainter({
    required this.discRadius,
    required this.glowOpacity,
    required this.arcStartAngle,
    required this.arcSweepAngle,
  });

  final double discRadius;
  final double glowOpacity;
  final double arcStartAngle;
  final double arcSweepAngle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // ── 发光弧线（主弧）──
    final arcRect = Rect.fromCircle(
      center: center,
      radius: discRadius + 2,
    );

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..color = _edgeCyan.withValues(alpha: (.72 * glowOpacity).clamp(0, 1));
    canvas.drawArc(arcRect, arcStartAngle, arcSweepAngle, false, arc);

    // ── 内层辅助弧（稍亮、稍细，产生双层光晕感）──
    final innerRect = Rect.fromCircle(
      center: center,
      radius: discRadius - .3,
    );
    final innerArc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..color = _edgeTeal.withValues(alpha: (.48 * glowOpacity).clamp(0, 1));
    canvas.drawArc(
      innerRect,
      arcStartAngle + .06,
      (arcSweepAngle - .12).clamp(0, arcSweepAngle),
      false,
      innerArc,
    );

    // ── 扩散光尾迹 ──
    final trailRect = Rect.fromCircle(
      center: center,
      radius: discRadius + 6,
    );
    final trail = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          Colors.transparent,
          _edgeCyan.withValues(alpha: (.08 * glowOpacity).clamp(0, 1)),
          Colors.transparent,
          Colors.transparent,
        ],
        stops: const [0, .56, .62, .68, 1],
      ).createShader(trailRect);
    canvas.drawArc(trailRect, arcStartAngle - .04, arcSweepAngle + .08, false,
        trail);
  }

  @override
  bool shouldRepaint(covariant _EdgeArcPainter old) =>
      old.discRadius != discRadius ||
      old.glowOpacity != glowOpacity ||
      old.arcStartAngle != arcStartAngle ||
      old.arcSweepAngle != arcSweepAngle;
}
