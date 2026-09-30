import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/media_item.dart';
import '../services/api_service.dart';
import '../utils/helpers.dart';
import 'video_player_screen.dart';

// Server ke videos ki list + naya video upload karna
class VideoListScreen extends StatefulWidget {
  final ApiService? api;
  const VideoListScreen({super.key, this.api});

  @override
  State<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  late final ApiService api;
  List<MediaItem> items = [];
  bool loading = true;
  bool uploading = false;
  double progress = 0;
  String? error;

  @override
  void initState() {
    super.initState();
    api = widget.api ?? ApiService();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await api.getList('videos');
      if (!mounted) return;
      setState(() {
        items = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
      });
    }
  }

  // Gallery se video chun kar server par bhejta hai
  Future<void> pickAndUpload() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      uploading = true;
      progress = 0;
    });
    try {
      await api.upload('videos', picked.path, onProgress: (p) {
        if (mounted) setState(() => progress = p);
      });
      if (mounted) showMessage(context, 'Video uploaded');
      await load();
    } catch (e) {
      if (mounted) showMessage(context, e.toString().replaceFirst('Exception: ', ''));
    }
    if (mounted) setState(() => uploading = false);
  }

  Future<void> deleteItem(MediaItem item) async {
    try {
      await api.delete('videos', item.id);
      load();
    } catch (e) {
      if (mounted) showMessage(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (error != null) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: load, child: const Text('Retry')),
          ],
        ),
      );
    } else if (items.isEmpty) {
      body = const Center(child: Text('No videos yet'));
    } else {
      body = ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            leading: const Icon(Icons.movie, color: Colors.blue),
            title: Text(item.fileName),
            subtitle: Text(formatSize(item.fileSize)),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    VideoPlayerScreen(title: item.fileName, url: item.fullUrl),
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => deleteItem(item),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Videos')),
      body: Column(
        children: [
          if (uploading) LinearProgressIndicator(value: progress),
          Expanded(child: body),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: uploading ? null : pickAndUpload,
        icon: const Icon(Icons.upload),
        label: const Text('Upload'),
      ),
    );
  }
}
