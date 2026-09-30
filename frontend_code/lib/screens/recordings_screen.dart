import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../services/api_service.dart';
import '../utils/helpers.dart';
import 'audio_player_screen.dart';

// Phone mein save ki hui recordings ki list
class RecordingsScreen extends StatefulWidget {
  const RecordingsScreen({super.key});

  @override
  State<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends State<RecordingsScreen> {
  final ApiService api = ApiService();
  List<File> files = [];
  bool loading = true;
  bool uploading = false;
  double progress = 0;

  @override
  void initState() {
    super.initState();
    loadFiles();
  }

  Future<void> loadFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    final recDir = Directory('${dir.path}/recordings');
    List<File> list = [];
    if (await recDir.exists()) {
      list = recDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.m4a'))
          .toList();
      // Nayi recording sabse upar
      list.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    }
    if (!mounted) return;
    setState(() {
      files = list;
      loading = false;
    });
  }

  Future<void> uploadFile(File file) async {
    setState(() {
      uploading = true;
      progress = 0;
    });
    try {
      await api.upload('audio', file.path, onProgress: (p) {
        if (mounted) setState(() => progress = p);
      });
      if (mounted) showMessage(context, 'Uploaded successfully');
    } catch (e) {
      if (mounted) showMessage(context, e.toString().replaceFirst('Exception: ', ''));
    }
    if (mounted) setState(() => uploading = false);
  }

  Future<void> deleteFile(File file) async {
    await file.delete();
    loadFiles();
  }

  String fileName(File f) => f.path.split(Platform.pathSeparator).last;

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (files.isEmpty) {
      body = const Center(child: Text('No recordings yet'));
    } else {
      body = ListView.builder(
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          return ListTile(
            leading: const Icon(Icons.play_circle, color: Colors.blue, size: 36),
            title: Text(fileName(file)),
            subtitle: Text(formatSize(file.lengthSync())),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AudioPlayerScreen(
                    title: fileName(file), source: file.path, isNetwork: false),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.cloud_upload),
                  onPressed: uploading ? null : () => uploadFile(file),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: uploading ? null : () => deleteFile(file),
                ),
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Recordings')),
      body: Column(
        children: [
          if (uploading) LinearProgressIndicator(value: progress),
          Expanded(child: body),
        ],
      ),
    );
  }
}
