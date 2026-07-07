import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';

import '../../bootstrap/demo_repository.dart';
import '../../bootstrap/demo_repository_extensions.dart';
import '../../design/melo_tokens.dart';
import '../../presentation/shell_accent.dart';
import '../../widgets/melo_components.dart';
import '../../widgets/melo_track_row.dart';
import '../../widgets/provider_tabs.dart';

part 'favorites_page_view.dart';
part 'favorites_list.dart';
part 'favorite_row.dart';
