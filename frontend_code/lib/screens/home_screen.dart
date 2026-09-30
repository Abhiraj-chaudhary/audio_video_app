import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'recorder_screen.dart';
import 'recordings_screen.dart';
import 'server_audio_screen.dart';
import 'video_list_screen.dart';

class HomeScreen extends StatefulWidget {
  final ApiService? api;
  const HomeScreen({super.key, this.api});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ApiService api;
  String serverStatus = 'Checking server...';
  bool serverOk = false;

  @override
  void initState() {
    super.initState();
    api = widget.api ?? ApiService();
    checkServer();
  }

  // /api/health call karke dekhta hai ki server chal raha hai ya nahi
  Future<void> checkServer() async {
    final ok = await api.checkHealth();
    if (!mounted) return;
    setState(() {
      serverOk = ok;
      serverStatus = ok ? 'Server connected' : 'Server not reachable';
    });
  }

  Widget menuButton(IconData icon, String text, Widget screen) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(text),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio & Video')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.circle,
                    size: 12, color: serverOk ? Colors.green : Colors.red),
                const SizedBox(width: 8),
                Text(serverStatus),
                const Spacer(),
                IconButton(
                    onPressed: checkServer, icon: const Icon(Icons.refresh)),
              ],
            ),
            const SizedBox(height: 8),
            menuButton(Icons.mic, 'Record Audio', const RecorderScreen()),
            menuButton(Icons.library_music, 'My Recordings',
                const RecordingsScreen()),
            menuButton(Icons.cloud_download, 'Uploaded Audio (Server)',
                const ServerAudioScreen()),
            menuButton(Icons.videocam, 'Videos', const VideoListScreen()),
          ],
        ),
      ),
    );
  }
}
