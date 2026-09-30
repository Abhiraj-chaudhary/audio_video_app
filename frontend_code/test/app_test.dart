import 'package:audio_video_app/models/media_item.dart';
import 'package:audio_video_app/screens/home_screen.dart';
import 'package:audio_video_app/screens/video_list_screen.dart';
import 'package:audio_video_app/services/api_service.dart';
import 'package:audio_video_app/utils/helpers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Asli server ke bina test karne ke liye nakli (fake) API.
// Har request ka jawab hum khud dete hain.
ApiService fakeApi(dynamic data) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test'));
  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
    handler.resolve(
        Response(requestOptions: options, statusCode: 200, data: data));
  }));
  return ApiService(dio: dio);
}

void main() {
  test('formatTime converts seconds to mm:ss', () {
    expect(formatTime(const Duration(seconds: 65)), '01:05');
    expect(formatTime(const Duration(seconds: 9)), '00:09');
  });

  test('MediaItem.fromJson reads server json', () {
    final item = MediaItem.fromJson({
      'id': 1,
      'file_name': 'a.m4a',
      'duration': 12,
      'file_size': 2048,
      'file_url': '/api/audio/1',
    });
    expect(item.id, 1);
    expect(item.fullUrl.endsWith('/api/audio/1'), true);
  });

  // API integration test
  test('ApiService.getList returns a list of items', () async {
    final api = fakeApi({
      'status': 'success',
      'items': [
        {
          'id': 5,
          'file_name': 'clip.mp4',
          'duration': 30,
          'file_size': 1000,
          'file_url': '/api/videos/5',
        }
      ]
    });
    final list = await api.getList('videos');
    expect(list.length, 1);
    expect(list.first.fileName, 'clip.mp4');
  });

  testWidgets('Home screen shows menu and server connected', (tester) async {
    await tester.pumpWidget(
        MaterialApp(home: HomeScreen(api: fakeApi({'status': 'ok'}))));
    await tester.pumpAndSettle();
    expect(find.text('Record Audio'), findsOneWidget);
    expect(find.text('My Recordings'), findsOneWidget);
    expect(find.text('Videos'), findsOneWidget);
    expect(find.text('Server connected'), findsOneWidget);
  });

  // Video screen ka empty state
  testWidgets('Video list shows empty message when no videos', (tester) async {
    await tester.pumpWidget(
        MaterialApp(home: VideoListScreen(api: fakeApi({'items': []}))));
    await tester.pumpAndSettle();
    expect(find.text('No videos yet'), findsOneWidget);
  });
}
