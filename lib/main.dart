import 'dart:async';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import 'data/db/app_database.dart';
import 'data/repositories/song_repository.dart';
import 'models/song.dart';
import 'services/audio_player_service.dart';
import 'state/library_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const MelodyBoxApp());
}

class MelodyBoxApp extends StatefulWidget {
  const MelodyBoxApp({super.key, this.audioPlayerService, this.songRepository});

  final AudioPlayerServiceBase? audioPlayerService;
  final SongRepositoryBase? songRepository;

  @override
  State<MelodyBoxApp> createState() => _MelodyBoxAppState();
}

class _MelodyBoxAppState extends State<MelodyBoxApp> {
  late final AudioPlayerServiceBase _audioPlayerService;
  late final SongRepositoryBase _songRepository;

  @override
  void initState() {
    super.initState();
    _audioPlayerService = widget.audioPlayerService ?? AudioPlayerService();
    _songRepository = widget.songRepository ?? SongRepository(AppDatabase());
  }

  @override
  void dispose() {
    _audioPlayerService.dispose();
    _songRepository.dispose();
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
      home: PlayerPage(
        audioPlayerService: _audioPlayerService,
        songRepository: _songRepository,
      ),
    );
  }
}

class PlayerPage extends StatefulWidget {
  const PlayerPage({
    super.key,
    required this.audioPlayerService,
    required this.songRepository,
  });

  final AudioPlayerServiceBase audioPlayerService;
  final SongRepositoryBase songRepository;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late final LibraryController _libraryController;
  late final StreamSubscription<Song?> _currentSongSubscription;
  late final StreamSubscription<Duration> _durationSubscription;

  String? _errorMessage;
  bool _isSeeking = false;
  double _seekPreviewMs = 0;

  @override
  void initState() {
    super.initState();
    _libraryController = LibraryController(
      songRepository: widget.songRepository,
    );
    unawaited(_libraryController.loadLibrary());
    _currentSongSubscription = widget.audioPlayerService.currentSongStream
        .listen((song) => unawaited(_libraryController.setCurrentSong(song)));
    _durationSubscription = widget.audioPlayerService.durationStream.listen(
      (duration) =>
          unawaited(_libraryController.updateCurrentSongDuration(duration)),
    );
  }

  @override
  void dispose() {
    _currentSongSubscription.cancel();
    _durationSubscription.cancel();
    _libraryController.dispose();
    super.dispose();
  }

  Future<void> _pickAudioFiles() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['mp3', 'flac', 'wav'],
        allowMultiple: true,
      );

      final paths = result?.files
          .map((file) => file.path)
          .whereType<String>()
          .toList();
      if (paths == null || paths.isEmpty) {
        return;
      }

      await _libraryController.importFiles(paths);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Unable to import the selected audio files.';
      });
    }
  }

  Future<void> _playAll() async {
    final songs = _libraryController.availableSongs;
    if (songs.isEmpty) {
      return;
    }

    await _runPlaybackAction(
      () => widget.audioPlayerService.playQueue(songs: songs, startIndex: 0),
      errorMessage: 'Unable to play the library.',
    );
  }

  Future<void> _playSong(Song song) async {
    if (!song.isAvailable) {
      setState(() {
        _errorMessage =
            'This file is unavailable. It may have been moved or deleted.';
      });
      return;
    }

    final songs = _libraryController.availableSongs;
    final index = _libraryController.indexOfAvailableSong(song);
    if (index == -1) {
      return;
    }

    await _runPlaybackAction(
      () =>
          widget.audioPlayerService.playQueue(songs: songs, startIndex: index),
      errorMessage: 'Unable to play this song.',
    );
  }

  Future<void> _togglePlayPause(bool isPlaying) async {
    final currentSong = _libraryController.currentSong;
    final songs = _libraryController.availableSongs;
    if (currentSong == null && songs.isEmpty) {
      return;
    }

    await _runPlaybackAction(() async {
      if (currentSong == null) {
        await widget.audioPlayerService.playQueue(songs: songs, startIndex: 0);
      } else if (isPlaying) {
        await widget.audioPlayerService.pause();
      } else {
        await widget.audioPlayerService.resume();
      }
    }, errorMessage: 'Playback failed.');
  }

  Future<void> _seekTo(double milliseconds) async {
    await _runPlaybackAction(
      () => widget.audioPlayerService.seek(
        Duration(milliseconds: milliseconds.round()),
      ),
      errorMessage: 'Unable to change playback position.',
    );
  }

  Future<void> _previous() async {
    await _runPlaybackAction(
      widget.audioPlayerService.previous,
      errorMessage: 'Unable to play the previous song.',
    );
  }

  Future<void> _next() async {
    await _runPlaybackAction(
      widget.audioPlayerService.next,
      errorMessage: 'Unable to play the next song.',
    );
  }

  Future<void> _runPlaybackAction(
    Future<void> Function() action, {
    required String errorMessage,
  }) async {
    setState(() {
      _errorMessage = null;
    });

    try {
      await action();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = errorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MelodyBox')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AnimatedBuilder(
            animation: _libraryController,
            builder: (context, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(
                    songCount: _libraryController.songs.length,
                    hasSongs: _libraryController.hasAvailableSongs,
                    onImport: _pickAudioFiles,
                    onPlayAll: _playAll,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _LibraryTable(
                      songs: _libraryController.songs,
                      currentSong: _libraryController.currentSong,
                      isLoading: _libraryController.isLoading,
                      onSongTap: _playSong,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SelectedSongInfo(song: _libraryController.currentSong),
                  const SizedBox(height: 16),
                  _PlaybackPanel(
                    audioPlayerService: widget.audioPlayerService,
                    canPlayback: _libraryController.hasAvailableSongs,
                    hasCurrentSong:
                        _libraryController.currentSong?.isAvailable == true,
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
                    onPrevious: _previous,
                    onNext: _next,
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
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.songCount,
    required this.hasSongs,
    required this.onImport,
    required this.onPlayAll,
  });

  final int songCount;
  final bool hasSongs;
  final VoidCallback onImport;
  final VoidCallback onPlayAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Music Library',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '$songCount songs saved locally',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: hasSongs ? onPlayAll : null,
          icon: const Icon(Icons.playlist_play),
          label: const Text('Play all'),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: onImport,
          icon: const Icon(Icons.audio_file),
          label: const Text('Import audio'),
        ),
      ],
    );
  }
}

class _LibraryTable extends StatelessWidget {
  const _LibraryTable({
    required this.songs,
    required this.currentSong,
    required this.isLoading,
    required this.onSongTap,
  });

  final List<Song> songs;
  final Song? currentSong;
  final bool isLoading;
  final ValueChanged<Song> onSongTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : songs.isEmpty
          ? const Center(
              child: Text('Import MP3, FLAC, or WAV files to start.'),
            )
          : Column(
              children: [
                const _LibraryHeaderRow(),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    itemCount: songs.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      return _SongRow(
                        index: index,
                        song: song,
                        isCurrent: currentSong?.id == song.id,
                        isAvailable: song.isAvailable,
                        onTap: () => onSongTap(song),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _LibraryHeaderRow extends StatelessWidget {
  const _LibraryHeaderRow();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text('#', style: style)),
          Expanded(flex: 4, child: Text('Title', style: style)),
          Expanded(flex: 2, child: Text('Artist', style: style)),
          Expanded(flex: 2, child: Text('Album', style: style)),
          SizedBox(width: 72, child: Text('Duration', style: style)),
        ],
      ),
    );
  }
}

class _SongRow extends StatelessWidget {
  const _SongRow({
    required this.index,
    required this.song,
    required this.isCurrent,
    required this.isAvailable,
    required this.onTap,
  });

  final int index;
  final Song song;
  final bool isCurrent;
  final bool isAvailable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isCurrent
          ? colorScheme.primaryContainer.withValues(alpha: 0.42)
          : Colors.transparent,
      child: InkWell(
        onTap: isAvailable ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Opacity(
            opacity: isAvailable ? 1 : 0.48,
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Icon(
                    _leadingIcon,
                    size: 18,
                    color: isCurrent
                        ? colorScheme.primary
                        : colorScheme.outline,
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Tooltip(
                    message: song.filePath,
                    child: Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.w700 : null,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    song.album,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: Text(
                    isAvailable
                        ? _formatNullableDuration(song.duration)
                        : 'Missing',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData get _leadingIcon {
    if (!isAvailable) {
      return Icons.error_outline;
    }

    return isCurrent ? Icons.volume_up : Icons.music_note;
  }
}

class _PlaybackPanel extends StatelessWidget {
  const _PlaybackPanel({
    required this.audioPlayerService,
    required this.canPlayback,
    required this.hasCurrentSong,
    required this.isSeeking,
    required this.seekPreviewMs,
    required this.onSeekStart,
    required this.onSeekChanged,
    required this.onSeekEnd,
    required this.onTogglePlayPause,
    required this.onPrevious,
    required this.onNext,
  });

  final AudioPlayerServiceBase audioPlayerService;
  final bool canPlayback;
  final bool hasCurrentSong;
  final bool isSeeking;
  final double seekPreviewMs;
  final ValueChanged<double> onSeekStart;
  final ValueChanged<double> onSeekChanged;
  final ValueChanged<double> onSeekEnd;
  final Future<void> Function(bool isPlaying) onTogglePlayPause;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

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
                      onChangeStart: hasCurrentSong ? onSeekStart : null,
                      onChanged: hasCurrentSong ? onSeekChanged : null,
                      onChangeEnd: hasCurrentSong ? onSeekEnd : null,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(
                            Duration(milliseconds: sliderValue.round()),
                          ),
                        ),
                        Text(_formatNullableDuration(duration)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton.filledTonal(
                          onPressed: hasCurrentSong ? onPrevious : null,
                          tooltip: 'Previous',
                          icon: const Icon(Icons.skip_previous),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: canPlayback
                              ? () => onTogglePlayPause(isPlaying)
                              : null,
                          icon: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                          ),
                          label: Text(isPlaying ? 'Pause' : 'Play'),
                        ),
                        const SizedBox(width: 12),
                        IconButton.filledTonal(
                          onPressed: hasCurrentSong ? onNext : null,
                          tooltip: 'Next',
                          icon: const Icon(Icons.skip_next),
                        ),
                      ],
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

class _SelectedSongInfo extends StatelessWidget {
  const _SelectedSongInfo({required this.song});

  final Song? song;

  @override
  Widget build(BuildContext context) {
    final currentSong = song;

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
              currentSong?.title ?? 'No song playing',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (currentSong != null) ...[
              const SizedBox(height: 4),
              Text(
                currentSong.filePath,
                maxLines: 1,
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

String _formatNullableDuration(Duration? duration) {
  if (duration == null || duration <= Duration.zero) {
    return '--';
  }

  return _formatDuration(duration);
}

String _formatDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
