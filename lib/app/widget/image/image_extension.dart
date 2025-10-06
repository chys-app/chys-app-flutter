import 'package:flutter/material.dart';

extension ImageExtension on String {
  /// Returns an Image.asset with optional height, width, and fit
  Image toImage({double? height, double? width, BoxFit? fit}) {
    return Image.asset(
      this,
      height: height,
      width: width,
      fit: fit,
    );
  }

  Image toNetworkImage({double? height, double? width, BoxFit? fit}) {
    return Image.network(
      this,
      height: height,
      width: width,
      fit: fit,
    );
  }

  /// Returns DecorationImage for background images
  DecorationImage toDecorationImage({BoxFit fit = BoxFit.cover}) {
    return DecorationImage(
      image: AssetImage(this),
      fit: fit,
    );
  }

  DecorationImage toDecorationNetworkImage({BoxFit fit = BoxFit.cover}) {
    return DecorationImage(
      image: NetworkImage(this),
      fit: fit,
    );
  }

  /// Converts to AssetImage directly (for flexibility)
  AssetImage get asset => AssetImage(this);
}
