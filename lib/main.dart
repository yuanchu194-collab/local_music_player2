import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import 'services/audio_player_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const MelodyBoxApp());
}

class MelodyBoxApp extends StatefulWidget {
  const MelodyBoxApp({super.key, this.audioPlayerService});

  final AudioPlayerServiceBase? audioPlayerService;

  @override
  State<MelodyBoxApp> createState() => _MelodyBoxAppState();
}

class _MelodyBoxAppState extends State<MelodyBoxApp> {
  late final AudioPlayerServiceBase _audioPlayerService;

  @override
  void initState() {
    super.initState();
    _audioPlayerService = widget.audioPlayerService ?? AudioPlayerService();
  }

  @override
  void dispose() {
    _audioPlayerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MelodyBox',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF22A96B)),
        useMaterial3: true,
      ),
      home: PlayerPage(audioPlayerService: _audioPlayerService),
    );
  }
}

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key, required this.audioPlayerService});

  final AudioPlayerServiceBase audioPlayerService;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  String? _selectedFilePath;
  String? _errorMessage;
  bool _isSeeking = false;
  double _seekPreviewMs = 0;

  Future<void> _pickAudioFile() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['mp3', 'flac', 'wav'],
        allowMultiple: false,
      );

      final path = result?.files.single.path;
      if (path == null) {
        return;
      }

      await widget.audioPlayerService.loadFile(path);

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedFilePath = path;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Unable to load this audio file.';
      });
    }
  }

  Future<void> _togglePlayPause(bool isPlaying) async {
    if (_selectedFilePath == null) {
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    try {
      if (isPlaying) {
        await widget.audioPlayerService.pause();
      } else {
        await widget.audioPlayerService.resume();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Playback failed.';
      });
    }
  }

  Future<void> _seekTo(double milliseconds) async {
    try {
      await widget.audioPlayerService.seek(
        Duration(milliseconds: milliseconds.round()),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Unable to change playback position.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MelodyBox')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Local music MVP',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Select one MP3, FLAC, or WAV file and control playback.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _pickAudioFile,
                  icon: const Icon(Icons.audio_file),
                  label: const Text('Select audio file'),
                ),
                const SizedBox(height: 24),
                _SelectedFileInfo(filePath: _selectedFilePath),
                const SizedBox(height: 16),
                _PlaybackPanel(
                  audioPlayerService: widget.audioPlayerService,
                  hasFile: _selectedFilePath != null,
                  isSeeking: _isSeeking,
                  seekPreviewMs: _seekPreviewMs,
                  onSeekStart: (value) {
                    setState(() {
                      _isSeeking = true;
                      _seekPreviewMs = value;
                    });
                  },
                  onSeekChanged: (value) {
                    setState(() {
                      _seekPreviewMs = value;
                    });
                  },
                  onSeekEnd: (value) async {
                    setState(() {
                      _isSeeking = false;
                    });
                    await _seekTo(value);
                  },
                  onTogglePlayPause: _togglePlayPause,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaybackPanel extends StatelessWidget {
  const _PlaybackPanel({
    required this.audioPlayerService,
    required this.hasFile,
    required this.isSeeking,
    required this.seekPreviewMs,
    required this.onSeekStart,
    required this.onSeekChanged,
    required this.onSeekEnd,
    required this.onTogglePlayPause,
  });

  final AudioPlayerServiceBase audioPlayerService;
  final bool hasFile;
  final bool isSeeking;
  final double seekPreviewMs;
  final ValueChanged<double> onSeekStart;
  final ValueChanged<double> onSeekChanged;
  final ValueChanged<double> onSeekEnd;
  final Future<void> Function(bool isPlaying) onTogglePlayPause;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: audioPlayerService.playingStream,
      initialData: false,
      builder: (context, playingSnapshot) {
        final isPlaying = playingSnapshot.data ?? false;

        return StreamBuilder<Duration>(
          stream: audioPlayerService.durationStream,
          initialData: Duration.zero,
          builder: (context, durationSnapshot) {
            final duration = durationSnapshot.data ?? Duration.zero;

            return StreamBuilder<Duration>(
              stream: audioPlayerService.positionStream,
              initialData: Duration.zero,
              builder: (context, positionSnapshot) {
                final position = positionSnapshot.data ?? Duration.zero;
                final maxMs = math.max(duration.inMilliseconds.toDouble(), 1);
                final rawValue = isSeeking
                    ? seekPreviewMs
                    : position.inMilliseconds.toDouble();
                final sliderValue = rawValue.clamp(0, maxMs).toDouble();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Slider(
                      value: sliderValue,
                      min: 0,
                      max: maxMs.toDouble(),
                      onChangeStart: hasFile ? onSeekStart : null,
                      onChanged: hasFile ? onSeekChanged : null,
                      onChangeEnd: hasFile ? onSeekEnd : null,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(
                            Duration(milliseconds: sliderValue.round()),
                          ),
                        ),
                        Text(_formatDuration(duration)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: FilledButton.icon(
                        onPressed: hasFile
                            ? () => onTogglePlayPause(isPlaying)
                            : null,
                        icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                        label: Text(isPlaying ? 'Pause' : 'Play'),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _SelectedFileInfo extends StatelessWidget {
  const _SelectedFileInfo({required this.filePath});

  final String? filePath;

  @override
  Widget build(BuildContext context) {
    final path = filePath;
    final title = path == null ? 'No file selected' : _fileNameFromPath(path);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (path != null) ...[
              const SizedBox(height: 4),
              Text(
                path,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _fileNameFromPath(String path) {
  return path.split(RegExp(r'[\\/]')).last;
}

String _formatDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
