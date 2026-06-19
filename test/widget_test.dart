import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:local_music_player2/data/repositories/song_repository.dart';
import 'package:local_music_player2/main.dart';
import 'package:local_music_player2/models/playback_mode.dart';
import 'package:local_music_player2/models/song.dart';
import 'package:local_music_player2/services/audio_player_service.dart';

void main() {
  testWidgets('shows the main shell controls', (WidgetTester tester) async {
    await tester.pumpWidget(
      MelodyBoxApp(
        audioPlayerService: _FakeAudioPlayerService(),
        songRepository: _FakeSongRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('MelodyBox'), findsOneWidget);
    expect(find.text('首页'), findsWidgets);
    expect(find.text('导入音乐'), findsOneWidget);
    expect(find.text('播放全部'), findsOneWidget);
    expect(find.text('暂无播放'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsWidgets);
  });
}

class _FakeSongRepository implements SongRepositoryBase {
  @override
  Future<void> dispose() async {}

  @override
  Future<List<Song>> importFiles(Iterable<String> filePaths) async {
    return filePaths.map(Song.fromFilePath).toList();
  }

  @override
  Future<List<Song>> loadSongs() async {
    return [];
  }

  @override
  Future<void> markPlayed(Song song) async {}

  @override
  Future<void> setFavorite(Song song, bool isFavorite) async {}

  @override
  Future<void> updateDuration(Song song, Duration duration) async {}
}

class _FakeAudioPlayerService implements AudioPlayerServiceBase {
  @override
  String? get currentFilePath => null;

  @override
  Song? get currentSong => null;

  @override
  PlaybackMode get playbackMode => PlaybackMode.sequence;

  @override
  double get volume => 1;

  @override
  Stream<String?> get currentFileStream => const Stream.empty();

  @override
  Stream<Song?> get currentSongStream => const Stream.empty();

  @override
  Stream<PlaybackMode> get playbackModeStream => const Stream.empty();

  @override
  Stream<Duration> get durationStream => const Stream.empty();

  @override
  Stream<bool> get playingStream => const Stream.empty();

  @override
  Stream<Duration> get positionStream => const Stream.empty();

  @override
  Stream<double> get volumeStream => const Stream.empty();

  @override
  Future<void> cyclePlaybackMode() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<void> loadFile(String filePath) async {}

  @override
  Future<void> loadSong(Song song) async {}

  @override
  Future<void> next() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> playFile(String filePath) async {}

  @override
  Future<void> playQueue({
    required List<Song> songs,
    required int startIndex,
  }) async {}

  @override
  Future<void> playSong(Song song) async {}

  @override
  Future<void> previous() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> setPlaybackMode(PlaybackMode mode) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> togglePlayPause() async {}
}
