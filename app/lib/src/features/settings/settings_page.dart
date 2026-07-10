import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider_contract/provider_contract.dart';
import 'package:provider_netease/provider_netease.dart';
import 'package:provider_qq/provider_qq.dart';
import 'package:provider_kugou/provider_kugou.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../bootstrap/demo_repository.dart';
import '../../bootstrap/app_version.dart';
import '../../bootstrap/backup/backup_coordinator.dart';
import '../../bootstrap/backup/backup_target.dart';
import '../../design/melo_tokens.dart';
import '../../presentation/app_destination.dart';
import '../../presentation/provider_presentation.dart';
import '../../widgets/melo_components.dart';
import '../../widgets/melo_logo_mark.dart';

part 'settings_page_view.dart';
part 'settings_audio_cache_card.dart';
part 'settings_source_card.dart';
