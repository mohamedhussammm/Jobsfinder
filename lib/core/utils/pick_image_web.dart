// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'pick_image_result.dart';

/// Web implementation: uses HTML file input element
Future<PickedImageResult?> pickImageCrossPlatform() async {
  final completer = Completer<PickedImageResult?>();
  final input = html.FileUploadInputElement()..accept = 'image/*';
  input.click();

  input.onChange.listen((event) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      completer.complete(null);
      return;
    }
    final file = files.first;
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    reader.onLoadEnd.listen((event) {
      final bytes = reader.result as Uint8List;
      completer.complete(PickedImageResult(bytes: bytes, name: file.name));
    });
    reader.onError.listen((_) => completer.complete(null));
  });

  // In case user cancels the dialog
  // We can't truly detect cancel, but a focus event after a delay hints at it
  html.window.onFocus.first.then((_) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!completer.isCompleted) completer.complete(null);
    });
  });

  return completer.future;
}
