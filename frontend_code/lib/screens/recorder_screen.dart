import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import '../utils/helpers.dart';

class RecorderScreen extends StatefulWidget {
  const RecorderScreen({super.key});

  @override
  State<RecorderScreen> createState() => _RecorderScreenState();
}

class _RecorderScreenState extends State<RecorderScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _timer;
  int _seconds = 0;
  bool _isRecording = false;
  bool _isPaused = false;
  bool _permanentlyDenied = false;
  String? _error;

  Future<void> _start() async {
    // Pehle mic ki permission maangte hain
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      setState(() {
        _permanentlyDenied = status.isPermanentlyDenied;
        _error = 'Microphone permission is needed to record.';
      });
      return;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final recDir = Directory('${dir.path}/recordings');
      if (!await recDir.exists()) await recDir.create(recursive: true);

      final name = 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: '${recDir.path}/$name',
      );

      setState(() {
        _isRecording = true;
        _isPaused = false;
        _seconds = 0;
        _error = null;
        _permanentlyDenied = false;
      });

      // Har second timer badhata hai (pause mein nahi badhta)
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!_isPaused) setState(() => _seconds++);
      });
    } catch (e) {
      setState(() => _error = 'Could not start recording: $e');
    }
  }

  Future<void> _pause() async {
    await _recorder.pause();
    setState(() => _isPaused = true);
  }

  Future<void> _resume() async {
    await _recorder.resume();
    setState(() => _isPaused = false);
  }

  Future<void> _stop() async {
    try {
      await _recorder.stop();
      _timer?.cancel();
      setState(() {
        _isRecording = false;
        _isPaused = false;
      });
      if (mounted) showMessage(context, 'Recording saved. See My Recordings.');
    } catch (e) {
      setState(() => _error = 'Could not stop recording: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Audio')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isRecording ? Icons.mic : Icons.mic_none,
              size: 100,
              color: _isRecording && !_isPaused ? Colors.red : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              formatTime(Duration(seconds: _seconds)),
              style: const TextStyle(fontSize: 40),
            ),
            Text(_isRecording
                ? (_isPaused ? 'Paused' : 'Recording...')
                : 'Ready'),
            const SizedBox(height: 24),
            if (!_isRecording)
              ElevatedButton.icon(
                onPressed: _start,
                icon: const Icon(Icons.fiber_manual_record),
                label: const Text('Start'),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isPaused ? _resume : _pause,
                    icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                    label: Text(_isPaused ? 'Resume' : 'Pause'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _stop,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                  ),
                ],
              ),
            if (_error != null) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(_error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red)),
              ),
              if (_permanentlyDenied)
                TextButton(
                  onPressed: openAppSettings,
                  child: const Text('Open Settings'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
