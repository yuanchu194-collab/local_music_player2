import 'dart:async';

import 'package:media_kit/media_kit.dart';

abstract interface class AudioPlayerServiceBase {
  String? get currentFilePath;

  Stream<Duration> get positionStream;

  Stream<Duration> get durationStream;

  Stream<bool> get playingStream;

  Stream<String?> get currentFileStream;

  Future<void> loadFile(String filePath);

  Future<void> playFile(String filePath);

  Future<void> play();

  Future<void> pause();

  Future<void> resume();

  Future<void> togglePlayPause();

  Future<void> seek(Duration position);

  Future<void> dispose();
}

class AudioPlayerService implements AudioPlayerServiceBase {
  AudioPlayerService() : _player = Player();

  final Player _player;
  final StreamController<String?> _currentFileController =
      StreamController<String?>.broadcast();

  String? _currentFilePath;

  @override
  String? get currentFilePath => _currentFilePath;

  @override
  Stream<Duration> get positionStream => _player.stream.position;

  @override
  Stream<Duration> get durationStream => _player.stream.duration;

  @override
  Stream<bool> get playingStream => _player.stream.playing;

  @override
  Stream<String?> get currentFileStream => _currentFileController.stream;

  @override
  Future<void> loadFile(String filePath) async {
    _currentFilePath = filePath;
    _currentFileController.add(filePath);
    await _player.open(Media(Uri.file(filePath).toString()), play: false);
  }

  @override
  Future<void> playFile(String filePath) async {
    _currentFilePath = filePath;
    _currentFileController.add(filePath);
    await _player.open(Media(Uri.file(filePath).toString()), play: true);
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
  Future<void> dispose() async {
    await _currentFileController.close();
    await _player.dispose();
  }
}
