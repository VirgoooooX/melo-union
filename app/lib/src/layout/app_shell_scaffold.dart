import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design/melo_tokens.dart';
import '../presentation/app_destination.dart';
import '../presentation/shell_accent.dart';
import '../widgets/desktop_player_bar.dart';
import '../widgets/desktop_lyrics_controller.dart';
import '../widgets/full_screen_player.dart';
import '../widgets/melo_logo_mark.dart';
import '../widgets/melo_local_mark.dart';
import '../widgets/right_sidebar.dart';
import '../widgets/melo_title_bar.dart';
import 'sidebar_widths_provider.dart';
import 'package:window_manager/window_manager.dart';

part 'app_shell_scaffold_view.dart';
part 'app_shell_scaffold_sidebar.dart';
