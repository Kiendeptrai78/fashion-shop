import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ImageStorageService {
  ImageStorageService({
    this.cloudName = const String.fromEnvironment(
      'CLOUDINARY_CLOUD_NAME',
      defaultValue: 'lbbgn51d',
    ),
    this.uploadPreset = const String.fromEnvironment(
      'CLOUDINARY_UPLOAD_PRESET',
      defaultValue: 'fashion_shop',
    ),
    http.Client? client,
  }) : _client = client;

  final String cloudName;
  final String uploadPreset;
  final http.Client? _client;

  Future<Uint8List> getImageDataFromAssets(String path) async {
    final data = await rootBundle.load(path);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  Future<String> uploadImageFile(String path, XFile image) async {
    return uploadImageData(path, await image.readAsBytes(), image.name);
  }

  Future<String> uploadImageData(String path, Uint8List image, String name) async {
    return _uploadMediaData(path, image, name, resourceType: 'image');
  }

  Future<String> uploadVideoData(String path, Uint8List video, String name) async {
    return _uploadMediaData(path, video, name, resourceType: 'video');
  }

  Future<String> _uploadMediaData(
    String path,
    Uint8List data,
    String name, {
    required String resourceType,
  }) async {
    if (cloudName.isEmpty || uploadPreset.isEmpty) {
      throw StateError('Image upload is not configured. Set CLOUDINARY_CLOUD_NAME '
          'and CLOUDINARY_UPLOAD_PRESET before starting the app.');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.https('api.cloudinary.com', '/v1_1/$cloudName/$resourceType/upload'),
    )
      ..fields['upload_preset'] = uploadPreset
      ..fields['asset_folder'] = path
      ..files.add(http.MultipartFile.fromBytes('file', data, filename: name));

    final client = _client ?? http.Client();
    try {
      final response = await http.Response.fromStream(await client.send(request));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = body['error'] as Map<String, dynamic>?;
        throw Exception(error?['message'] ?? 'Upload failed (${response.statusCode}).');
      }
      final url = body['secure_url'] as String?;
      if (url == null || !url.startsWith('https://')) {
        throw const FormatException('Upload did not return a secure URL.');
      }
      return url;
    } finally {
      if (_client == null) client.close();
    }
  }
}
