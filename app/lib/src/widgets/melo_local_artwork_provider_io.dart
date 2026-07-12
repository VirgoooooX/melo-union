import 'dart:io';

import 'package:flutter/widgets.dart';

ImageProvider<Object> meloLocalArtworkProvider(Uri artwork) =>
    FileImage(File(artwork.toFilePath()));
