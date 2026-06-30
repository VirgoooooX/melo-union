import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bootstrap/demo_repository.dart';
import '../design/melo_tokens.dart';
import '../presentation/provider_presentation.dart';
import 'queue_track_cover.dart';
import 'lyrics_provider.dart';

part 'right_sidebar_now_playing.dart';
part 'queue_preview.dart';

enum RightSidebarMode {
  queue,
  lyrics,
}

final rightSidebarModeProvider =
    StateProvider<RightSidebarMode>((ref) => RightSidebarMode.queue);
