import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  /// Picks an image from the specified source (camera or gallery),
  /// resizes it for profile use, and returns it as a Base64 string.
  Future<String?> pickImageAsBase64(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512, // Profile avatar – optimized for retina at display size
        maxHeight: 512,
        imageQuality: 75, // ~60-100KB vs ~5MB original – good quality/size balance
      );

      if (image == null) return null;

      final Uint8List bytes = await image.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      // Log error or handle appropriately in a real app
      return null;
    }
  }
}
