import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageProcessingService {
  /// Removes white background from a JPEG/PNG and returns a transparent PNG
  static Uint8List removeBackground(Uint8List bytes) {
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return bytes;

    // Convert to 32-bit (RGBA) if it's not already
    img.Image rgbaImage = image.convert(numChannels: 4);

    for (int y = 0; y < rgbaImage.height; y++) {
      for (int x = 0; x < rgbaImage.width; x++) {
        img.Pixel pixel = rgbaImage.getPixel(x, y);
        
        // Check if the pixel is "close to white"
        // We look for high values in R, G, and B
        num r = pixel.r;
        num g = pixel.g;
        num b = pixel.b;

        // If pixel is very light (threshold of 230 out of 255), make it transparent
        if (r > 230 && g > 230 && b > 230) {
          rgbaImage.setPixelRgba(x, y, 0, 0, 0, 0);
        }
      }
    }

    return Uint8List.fromList(img.encodePng(rgbaImage));
  }
}
