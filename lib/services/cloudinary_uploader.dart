import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class CloudinaryUploader {
  static const String _cloudName = 'dqewca7mp';
  static const String _uploadPreset = 'unibazaar_preset';

  const CloudinaryUploader();

  Future<String> uploadImage(File file) async {
    // 1️⃣ Check file size
    final length = await file.length();
    if (length == 0) {
      throw Exception("Image file is empty.");
    }

    // 2️⃣ Detect file type
    final ext = file.path.split('.').last.toLowerCase();
    String subtype = ext == 'png' ? 'png' : 'jpeg';

    // 3️⃣ Cloudinary URL
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    // 4️⃣ Build request
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..headers['User-Agent'] =
          'FlutterApp/1.0' // ADD THIS
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType('image', subtype),
        ),
      );

    // 5️⃣ Send with TIMEOUT
    final response = await request.send().timeout(const Duration(seconds: 15));

    final body = await response.stream.bytesToString();

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Cloudinary upload failed: $body');
    }

    final match = RegExp(r'"secure_url"\s*:\s*"([^"]+)"').firstMatch(body);
    if (match == null) {
      throw Exception('secure_url not found in Cloudinary response');
    }

    return match.group(1)!;
  }
}
