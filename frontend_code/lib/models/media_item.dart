import '../constants.dart';

// Server se aane wali ek audio ya video file ki details
class MediaItem {
  final int id;
  final String fileName;
  final int duration; // seconds
  final int fileSize; // bytes
  final String fileUrl;

  MediaItem({
    required this.id,
    required this.fileName,
    required this.duration,
    required this.fileSize,
    required this.fileUrl,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'],
      fileName: json['file_name'],
      duration: json['duration'] ?? 0,
      fileSize: json['file_size'] ?? 0,
      fileUrl: json['file_url'],
    );
  }

  // Player ko poora URL chahiye
  String get fullUrl => '$baseUrl$fileUrl';
}
