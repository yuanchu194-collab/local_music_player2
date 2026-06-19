import 'dart:async';
import 'dart:math';

import 'package:media_kit/media_kit.dart';

import '../models/playback_mode.dart';
import '../models/song.dart';

abstract interface class AudioPlayerServiceBase {
  String? get currentFilePath;

  Song? get currentSong;

  PlaybackMode get playbackMode;

  double get volume;

  Stream<Duration> get positionStream;

  Stream<Duration> get durationStream;

  Stream<bool> get playingStream;

  Stream<String?> get currentFileStream;

  Stream<Song?> get currentSongStream;

  Stream<PlaybackMode> get playbackModeStream;

  Stream<double> get volumeStream;

  Future<void> loadFile(String filePath);

  Future<void> playFile(String filePath);

  Future<void> loadSong(Song song);

  Future<void> playSong(Song song);

  Future<void> playQueue({required List<Song> songs, required int startIndex});

  Future<void> play();

  Future<void> pause();

  Future<void> resume();

  Future<void> togglePlayPause();

  Future<void> seek(Duration position);

  Future<void> next();

  Future<void> previous();

  Future<void> setPlaybackMode(PlaybackMode mode);

  Future<void> cyclePlaybackMode();

  Future<void> setVolume(double volume);

  Future<void> dispose();
}

class AudioPlayerService implements AudioPlayerServiceBase {
  AudioPlayerService() : _player = Player() {
    _completedSubscription = _player.stream.completed.listen((completed) {
      if (completed) {
        unawaited(_handlePlaybackCompleted());
      }
    });
  }

  final Player _player;
  final Random _random = Random();
  final StreamController<String?> _currentFileController =
      StreamController<String?>.broadcast();
  final StreamController<Song?> _currentSongController =
      StreamController<Song?>.broadcast();
  final StreamController<PlaybackMode> _playbackModeController =
      StreamController<PlaybackMode>.broadcast();
  final StreamController<double> _volumeController =
      StreamController<double>.broadcast();

  late final StreamSubscription<bool> _completedSubscription;

  String? _currentFilePath;
  Song? _currentSong;
  PlaybackMode _playbackMode = PlaybackMode.sequence;
  double _volume = 1;
  List<Song> _queue = [];
  int _currentIndex = -1;
  bool _isHandlingCompletion = false;

  @override
  String? get currentFilePath => _currentFilePath;

  @override
  Song? get currentSong => _currentSong;

  @override
  PlaybackMode get playbackMode => _playbackMode;

  @override
  double get volume => _volume;

  @override
  Stream<Duration> get positionStream => _player.stream.position;

  @override
  Stream<Duration> get durationStream => _player.stream.duration;

  @override
  Stream<bool> get playingStream => _player.stream.playing;

  @override
  Stream<String?> get currentFileStream => _currentFileController.stream;

  @override
  Stream<Song?> get currentSongStream => _currentSongController.stream;

  @override
  Stream<PlaybackMode> get playbackModeStream => _playbackModeController.stream;

  @override
  Stream<double> get volumeStream => _volumeController.stream;

  @override
  Future<void> loadFile(String filePath) async {
    await loadSong(Song.fromFilePath(filePath));
  }

  @override
  Future<void> playFile(String filePath) async {
    await playSong(Song.fromFilePath(filePath));
  }

  @override
  Future<void> loadSong(Song song) async {
    _queue = [song];
    _currentIndex = 0;
    await _openSong(song, play: false);
  }

  @override
  Future<void> playSong(Song song) async {
    _queue = [song];
    _currentIndex = 0;
    await _openSong(song, play: true);
  }

  @override
  Future<void> playQueue({
    required List<Song> songs,
    required int startIndex,
  }) async {
    if (songs.isEmpty || startIndex < 0 || startIndex >= songs.length) {
      return;
    }

    _queue = List<Song>.of(songs);
    _currentIndex = startIndex;
    await _openSong(_queue[_currentIndex], play: true);
  }

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> resume() async {
    await _player.play();
  }

  @override
  Future<void> togglePlayPause() async {
    if (_player.state.playing) {
      await pause();
      return;
    }

    await resume();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> next() async {
    final nextIndex = _nextIndexForManualAction();
    if (nextIndex == null) {
      if (_playbackMode == PlaybackMode.repeatOne && _currentSong != null) {
        await _replayCurrentSong();
      }
      return;
    }

    _currentIndex = nextIndex;
    await _openSong(_queue[_currentIndex], play: true);
  }

  @override
  Future<void> previous() async {
    final previousIndex = _previousIndexForManualAction();
    if (previousIndex == null) {
      if (_playbackMode == PlaybackMode.repeatOne && _currentSong != null) {
        await _replayCurrentSong();
      }
      return;
    }

    _currentIndex = previousIndex;
    await _openSong(_queue[_currentIndex], play: true);
  }

  @override
  Future<void> setPlaybackMode(PlaybackMode mode) async {
    if (_playbackMode == mode) {
      return;
    }

    _playbackMode = mode;
    _playbackModeController.add(mode);
  }

  @override
  Future<void> cyclePlaybackMode() async {
    final modes = PlaybackMode.values;
    final nextMode = modes[(_playbackMode.index + 1) % modes.length];
    await setPlaybackMode(nextMode);
  }

  @override
  Future<void> setVolume(double volume) async {
    final clampedVolume = volume.clamp(0, 1).toDouble();
    _volume = clampedVolume;
    _volumeController.add(clampedVolume);
    await _player.setVolume(clampedVolume * 100);
  }

  @override
  Future<void> dispose() async {
    await _completedSubscription.cancel();
    await _currentFileController.close();
    await _currentSongController.close();
    await _playbackModeController.close();
    await _volumeController.close();
    await _player.dispose();
  }

  Future<void> _openSong(Song song, {required bool play}) async {
    _isHandlingCompletion = false;
    _currentSong = song;
    _currentFilePath = song.filePath;
    _currentSongController.add(song);
    _currentFileController.add(song.filePath);
    await _player.open(Media(Uri.file(song.filePath).toString()), play: play);
  }

  Future<void> _handlePlaybackCompleted() async {
    if (_isHandlingCompletion || _queue.isEmpty || _currentIndex == -1) {
      return;
    }

    _isHandlingCompletion = true;

    try {
      switch (_playbackMode) {
        case PlaybackMode.sequence:
          if (_currentIndex < _queue.length - 1) {
            _currentIndex += 1;
            await _openSong(_queue[_currentIndex], play: true);
          }
        case PlaybackMode.repeatAll:
          _currentIndex = _currentIndex >= _queue.length - 1
              ? 0
              : _currentIndex + 1;
          await _openSong(_queue[_currentIndex], play: true);
        case PlaybackMode.repeatOne:
          await _replayCurrentSong();
        case PlaybackMode.shuffle:
          _currentIndex = _randomQueueIndex();
          await _openSong(_queue[_currentIndex], play: true);
      }
    } finally {
      _isHandlingCompletion = false;
    }
  }

  Future<void> _replayCurrentSong() async {
    final currentSong = _currentSong;
    if (currentSong == null) {
      return;
    }

    _currentSongController.add(currentSong);
    await _player.seek(Duration.zero);
    await _player.play();
  }

  int? _nextIndexForManualAction() {
    if (_queue.isEmpty || _currentIndex == -1) {
      return null;
    }

    switch (_playbackMode) {
      case PlaybackMode.sequence:
        return _currentIndex < _queue.length - 1 ? _currentIndex + 1 : null;
      case PlaybackMode.repeatAll:
        return _currentIndex >= _queue.length - 1 ? 0 : _currentIndex + 1;
      case PlaybackMode.repeatOne:
        return null;
      case PlaybackMode.shuffle:
        return _randomQueueIndex();
    }
  }

  int? _previousIndexForManualAction() {
    if (_queue.isEmpty || _currentIndex == -1) {
      return null;
    }

    switch (_playbackMode) {
      case PlaybackMode.sequence:
        return _currentIndex > 0 ? _currentIndex - 1 : null;
      case PlaybackMode.repeatAll:
        return _currentIndex <= 0 ? _queue.length - 1 : _currentIndex - 1;
      case PlaybackMode.repeatOne:
        return null;
      case PlaybackMode.shuffle:
        return _randomQueueIndex();
    }
  }

  int _randomQueueIndex() {
    if (_queue.length <= 1) {
      return 0;
    }

    var nextIndex = _random.nextInt(_queue.length);
    while (nextIndex == _currentIndex) {
      nextIndex = _random.nextInt(_queue.length);
    }
    return nextIndex;
  }
}
