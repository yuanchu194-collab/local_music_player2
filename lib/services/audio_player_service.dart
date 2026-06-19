import 'dart:async';

import 'package:media_kit/media_kit.dart';

import '../models/song.dart';

abstract interface class AudioPlayerServiceBase {
  String? get currentFilePath;

  Song? get currentSong;

  Stream<Duration> get positionStream;

  Stream<Duration> get durationStream;

  Stream<bool> get playingStream;

  Stream<String?> get currentFileStream;

  Stream<Song?> get currentSongStream;

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

  Future<void> dispose();
}

class AudioPlayerService implements AudioPlayerServiceBase {
  AudioPlayerService() : _player = Player();

  final Player _player;
  final StreamController<String?> _currentFileController =
      StreamController<String?>.broadcast();
  final StreamController<Song?> _currentSongController =
      StreamController<Song?>.broadcast();

  String? _currentFilePath;
  Song? _currentSong;
  List<Song> _queue = [];
  int _currentIndex = -1;

  @override
  String? get currentFilePath => _currentFilePath;

  @override
  Song? get currentSong => _currentSong;

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
    if (_queue.isEmpty || _currentIndex >= _queue.length - 1) {
      return;
    }

    _currentIndex += 1;
    await _openSong(_queue[_currentIndex], play: true);
  }

  @override
  Future<void> previous() async {
    if (_queue.isEmpty || _currentIndex <= 0) {
      return;
    }

    _currentIndex -= 1;
    await _openSong(_queue[_currentIndex], play: true);
  }

  @override
  Future<void> dispose() async {
    await _currentFileController.close();
    await _currentSongController.close();
    await _player.dispose();
  }

  Future<void> _openSong(Song song, {required bool play}) async {
    _currentSong = song;
    _currentFilePath = song.filePath;
    _currentSongController.add(song);
    _currentFileController.add(song.filePath);
    await _player.open(Media(Uri.file(song.filePath).toString()), play: play);
  }
}
