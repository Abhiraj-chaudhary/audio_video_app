import 'package:dio/dio.dart';
import '../constants.dart';
import '../models/media_item.dart';

// Flask server se baat karne ka saara code yahan hai.
// type = 'audio' ya 'videos'
class ApiService {
  final Dio dio;

  ApiService({Dio? dio})
      : dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(seconds: 60),
            ));

  Future<bool> checkHealth() async {
    try {
      final res = await dio.get('/api/health');
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<MediaItem>> getList(String type) async {
    try {
      final res = await dio.get('/api/$type');
      final items = res.data['items'] as List;
      return items.map((e) => MediaItem.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  Future<void> upload(String type, String filePath,
      {void Function(double)? onProgress}) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      await dio.post(
        '/api/$type/upload',
        data: form,
        onSendProgress: (sent, total) {
          if (total > 0 && onProgress != null) onProgress(sent / total);
        },
      );
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  Future<void> delete(String type, int id) async {
    try {
      await dio.delete('/api/$type/$id');
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  // Error ko user ke liye simple message mein badalta hai
  String _errorMessage(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Server is taking too long (timeout)';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot connect to server. Is it running?';
    }
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return 'Something went wrong (${e.response?.statusCode})';
  }
}
