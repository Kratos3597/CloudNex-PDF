import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class ImageEngine {
  /// Removes white background from a JPEG/PNG and returns a transparent PNG
  /// Uses compute to run in a separate isolate
  static Future<Uint8List> removeBackgroundAsync(Uint8List bytes) async {
    return await compute(removeBackground, bytes);
  }

  static Uint8List removeBackground(Uint8List bytes) {
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return bytes;

    // Convert to 32-bit (RGBA) if it's not already
    img.Image rgbaImage = image.convert(numChannels: 4);

    for (int y = 0; y < rgbaImage.height; y++) {
      for (int x = 0; x < rgbaImage.width; x++) {
        img.Pixel pixel = rgbaImage.getPixel(x, y);
        
        // Check if the pixel is "close to white"
        num r = pixel.r;
        num g = pixel.g;
        num b = pixel.b;

        if (r > 230 && g > 230 && b > 230) {
          rgbaImage.setPixelRgba(x, y, 0, 0, 0, 0);
        }
      }
    }

    return Uint8List.fromList(img.encodePng(rgbaImage));
  }
}
