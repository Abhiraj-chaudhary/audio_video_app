import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../utils/helpers.dart';

// Audio play karne wali screen. Local file aur server ka audio, dono chalte hain.
class AudioPlayerScreen extends StatefulWidget {
  final String title;
  final String source; // file path ya URL
  final bool isNetwork;

  const AudioPlayerScreen({
    super.key,
    required this.title,
    required this.source,
    required this.isNetwork,
  });

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final AudioPlayer _player = AudioPlayer();
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;
  bool _playing = false;
  bool _loading = true;
  double _speed = 1.0;
  double _volume = 1.0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Player ke changes sunte hain aur screen update karte hain
    _player.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.durationStream.listen((d) {
      if (mounted && d != null) setState(() => _total = d);
    });
    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() => _playing = state.playing);
      // Audio khatam ho gaya toh shuru par le jao
      if (state.processingState == ProcessingState.completed) {
        _player.pause();
        _player.seek(Duration.zero);
      }
    });

    try {
      if (widget.isNetwork) {
        await _player.setUrl(widget.source);
      } else {
        await _player.setFilePath(widget.source);
      }
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Cannot play this audio. The file may be corrupted or the server is not reachable.';
        });
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxMs = _total.inMilliseconds > 0 ? _total.inMilliseconds.toDouble() : 1.0;
    final posMs = _position.inMilliseconds.toDouble().clamp(0.0, maxMs);

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red)),
        ),
      );
    } else {
      body = Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_note, size: 100, color: Colors.blue),
            const SizedBox(height: 24),
            // Seek bar
            Slider(
              value: posMs,
              max: maxMs,
              onChanged: (v) => _player.seek(Duration(milliseconds: v.toInt())),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatTime(_position)),
                Text(formatTime(_total)),
              ],
            ),
            const SizedBox(height: 12),
            // Play / Pause
            IconButton(
              iconSize: 72,
              icon: Icon(_playing ? Icons.pause_circle : Icons.play_circle),
              onPressed: () => _playing ? _player.pause() : _player.play(),
            ),
            const SizedBox(height: 16),
            // Speed control
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Speed: '),
                DropdownButton<double>(
                  value: _speed,
                  items: const [0.5, 1.0, 1.5, 2.0]
                      .map((s) => DropdownMenuItem(value: s, child: Text('${s}x')))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _speed = v);
                    _player.setSpeed(v);
                  },
                ),
              ],
            ),
            // Volume control
            Row(
              children: [
                const Icon(Icons.volume_up),
                Expanded(
                  child: Slider(
                    value: _volume,
                    onChanged: (v) {
                      setState(() => _volume = v);
                      _player.setVolume(v);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: body,
    );
  }
}
