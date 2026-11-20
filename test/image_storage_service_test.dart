import 'dart:convert';
import 'dart:typed_data';

import 'package:fashion_business_app/data/services/image_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  test('uploads image bytes and returns the Cloudinary HTTPS URL', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.toString(), 'https://api.cloudinary.com/v1_1/test-cloud/image/upload');
      expect(request.headers['content-type'], startsWith('multipart/form-data'));
      expect(request.body, contains('test-preset'));
      expect(request.body, contains('Products/Images'));
      expect(request.body, contains('photo.png'));
      return http.Response(jsonEncode({'secure_url': 'https://res.cloudinary.com/test/photo.png'}), 200);
    });
    final service = ImageStorageService(
        cloudName: 'test-cloud', uploadPreset: 'test-preset', client: client);
    final url = await service.uploadImageFile('Products/Images',
        XFile.fromData(Uint8List.fromList([1, 2, 3]), path: 'photo.png'));
    expect(url, 'https://res.cloudinary.com/test/photo.png');
  });

  test('rejects missing configuration before making a request', () async {
    var requested = false;
    final service = ImageStorageService(cloudName: '', uploadPreset: '',
        client: MockClient((_) async {
          requested = true;
          return http.Response('{}', 200);
        }));
    await expectLater(service.uploadImageData('Products', Uint8List(0), 'photo.png'),
        throwsStateError);
    expect(requested, isFalse);
  });

  test('surfaces the provider error without returning a URL to save', () async {
    final service = ImageStorageService(cloudName: 'test', uploadPreset: 'invalid',
        client: MockClient((_) async => http.Response(
            jsonEncode({'error': {'message': 'Upload preset not found'}}), 400)));
    await expectLater(service.uploadImageData('Products', Uint8List(0), 'photo.png'),
        throwsA(predicate((error) => error.toString().contains('Upload preset not found'))));
  });

  test('rejects a successful response without a secure URL', () async {
    final service = ImageStorageService(cloudName: 'test', uploadPreset: 'preset',
        client: MockClient((_) async => http.Response('{"url":"http://example.com/image.png"}', 200)));
    await expectLater(service.uploadImageData('Products', Uint8List(0), 'photo.png'),
        throwsFormatException);
  });
}
