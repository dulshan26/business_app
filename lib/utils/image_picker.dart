import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

final ImagePicker picker = ImagePicker();

Future<Uint8List?> pickImage() async {
  final XFile? file = await picker.pickImage(source: ImageSource.gallery);

  if (file == null) return null;

  return await file.readAsBytes();
}
