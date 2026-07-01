import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:window_manager/window_manager.dart';
import '../design/melo_tokens.dart';
import 'melo_logo_mark.dart';

class MeloTitleBar extends StatefulWidget {
  const MeloTitleBar({super.key});

  @override
  State<MeloTitleBar> createState() => _MeloTitleBarState();
}

class _MeloTitleBarState extends State<MeloTitleBar> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _checkMaximizedState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _checkMaximizedState() async {
    final isMaximized = await windowManager.isMaximized();
    if (mounted) {
      setState(() {
        _isMaximized = isMaximized;
      });
    }
  }

  @override
  void onWindowMaximize() {
    setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    setState(() => _isMaximized = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: const BoxDecoration(
        color: MeloColors.surface,
        border: Border(
          bottom: BorderSide(
            color: MeloColors.border,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 18),
          const MeloLogoMark(size: 28),
          const SizedBox(width: 10),
          Text(
            'MeloUnion',
            style: GoogleFonts.montserrat(
              color: const Color(0xFF0F172A),
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onDoubleTap: () async {
                if (_isMaximized) {
                  await windowManager.unmaximize();
                } else {
                  await windowManager.maximize();
                }
              },
              child: const DragToMoveArea(
                child: SizedBox.expand(),
              ),
            ),
          ),
          _WindowControlButton(
            icon: Icons.remove_rounded,
            onPressed: () => windowManager.minimize(),
            hoverColor: MeloColors.surfaceHover,
          ),
          _WindowControlButton(
            icon: _isMaximized
                ? Icons.filter_none_rounded
                : Icons.crop_square_rounded,
            iconSize: 13,
            onPressed: () async {
              if (_isMaximized) {
                await windowManager.unmaximize();
              } else {
                await windowManager.maximize();
              }
            },
            hoverColor: MeloColors.surfaceHover,
          ),
          _WindowControlButton(
            icon: Icons.close_rounded,
            onPressed: () => windowManager.close(),
            hoverColor: const Color(0xE5E81123),
            hoverIconColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _WindowControlButton extends StatefulWidget {
  const _WindowControlButton({
    required this.icon,
    required this.onPressed,
    required this.hoverColor,
    this.hoverIconColor,
    this.iconSize = 16,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color hoverColor;
  final Color? hoverIconColor;
  final double iconSize;

  @override
  State<_WindowControlButton> createState() => _WindowControlButtonState();
}

class _WindowControlButtonState extends State<_WindowControlButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 42,
          height: double.infinity,
          color: _hovered ? widget.hoverColor : Colors.transparent,
          child: Center(
            child: Icon(
              widget.icon,
              size: widget.iconSize,
              color: _hovered
                  ? (widget.hoverIconColor ?? MeloColors.textPrimary)
                  : MeloColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
