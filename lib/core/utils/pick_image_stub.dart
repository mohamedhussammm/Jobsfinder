import 'package:image_picker/image_picker.dart';
import 'pick_image_result.dart';

/// Mobile/desktop stub: uses image_picker
Future<PickedImageResult?> pickImageCrossPlatform() async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 1200,
    imageQuality: 85,
  );
  if (picked == null) return null;
  final bytes = await picked.readAsBytes();
  return PickedImageResult(bytes: bytes, name: picked.name);
}
