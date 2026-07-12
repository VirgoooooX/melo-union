import 'package:flutter/widgets.dart';

ImageProvider<Object> meloLocalArtworkProvider(Uri artwork) =>
    NetworkImage(artwork.toString());
