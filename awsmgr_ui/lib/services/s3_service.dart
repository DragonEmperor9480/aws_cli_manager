import 'dart:io';
import 'package:dio/dio.dart';

class S3Service {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:8080/api',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 5),
  ));

  /// Download S3 object with progress tracking
  static Future<List<int>> downloadWithProgress(
    String bucketName,
    String objectKey,
    Function(int received, int total) onProgress,
  ) async {
    try {
      print('Starting download: $bucketName/$objectKey');
      
      final response = await _dio.get<List<int>>(
        '/s3/buckets/$bucketName/objects/$objectKey',
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(minutes: 5),
        ),
        onReceiveProgress: (received, total) {
          print('Progress: $received / $total bytes');
          if (total != -1) {
            onProgress(received, total);
          }
        },
      );

      print('Download complete');
      return response.data ?? [];
    } catch (e) {
      print('Download error: $e');
      throw Exception('Download failed: $e');
    }
  }

  /// Upload S3 object with progress tracking
  static Future<void> uploadWithProgress(
    String bucketName,
    String objectKey,
    File file,
    Function(int sent, int total) onProgress,
  ) async {
    try {
      final fileName = objectKey.split('/').last;
      final formData = FormData.fromMap({
        'key': objectKey,
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      await _dio.post(
        '/s3/buckets/$bucketName/upload',
        data: formData,
        onSendProgress: (sent, total) {
          if (total != -1) {
            onProgress(sent, total);
          }
        },
      );
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }
}
