import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../services/api_service.dart';
import '../utils/helpers.dart';
import 'audio_player_screen.dart';

// Server par upload hui audio files ki list
class ServerAudioScreen extends StatefulWidget {
  final ApiService? api;
  const ServerAudioScreen({super.key, this.api});

  @override
  State<ServerAudioScreen> createState() => _ServerAudioScreenState();
}

class _ServerAudioScreenState extends State<ServerAudioScreen> {
  late final ApiService api;
  List<MediaItem> items = [];
  bool loading = true;
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
      final result = await api.getList('audio');
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

  Future<void> deleteItem(MediaItem item) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete?'),
        content: Text('Delete ${item.fileName} from server?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (sure != true) return;
    try {
      await api.delete('audio', item.id);
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
      body = const Center(child: Text('No uploaded audio yet'));
    } else {
      body = ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            leading: const Icon(Icons.audiotrack, color: Colors.blue),
            title: Text(item.fileName),
            subtitle: Text(
                '${formatTime(Duration(seconds: item.duration))}  |  ${formatSize(item.fileSize)}'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AudioPlayerScreen(
                    title: item.fileName, source: item.fullUrl, isNetwork: true),
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
      appBar: AppBar(title: const Text('Uploaded Audio')),
      body: body,
    );
  }
}
