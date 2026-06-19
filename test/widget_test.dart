import 'package:flutter_test/flutter_test.dart';

import 'package:local_music_player2/main.dart';
import 'package:local_music_player2/services/audio_player_service.dart';

void main() {
  testWidgets('shows the MVP player controls', (WidgetTester tester) async {
    await tester.pumpWidget(
      MelodyBoxApp(audioPlayerService: _FakeAudioPlayerService()),
    );

    expect(find.text('MelodyBox'), findsOneWidget);
    expect(find.text('Select audio file'), findsOneWidget);
    expect(find.text('No file selected'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
  });
}

class _FakeAudioPlayerService implements AudioPlayerServiceBase {
  @override
  String? get currentFilePath => null;

  @override
  Stream<String?> get currentFileStream => const Stream.empty();

  @override
  Stream<Duration> get durationStream => const Stream.empty();

  @override
  Stream<bool> get playingStream => const Stream.empty();

  @override
  Stream<Duration> get positionStream => const Stream.empty();

  @override
  Future<void> dispose() async {}

  @override
  Future<void> loadFile(String filePath) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> playFile(String filePath) async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> togglePlayPause() async {}
}
