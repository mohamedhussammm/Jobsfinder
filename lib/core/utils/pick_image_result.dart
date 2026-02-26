import 'dart:typed_data';

/// Result of picking an image
class PickedImageResult {
  final Uint8List bytes;
  final String name;

  PickedImageResult({required this.bytes, required this.name});
}
