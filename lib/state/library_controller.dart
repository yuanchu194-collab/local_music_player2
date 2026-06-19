import 'package:flutter/foundation.dart';

import '../models/song.dart';

class LibraryController extends ChangeNotifier {
  final List<Song> _songs = [];
  Song? _currentSong;

  List<Song> get songs => List.unmodifiable(_songs);

  Song? get currentSong => _currentSong;

  bool get hasSongs => _songs.isNotEmpty;

  void addFiles(Iterable<String> filePaths) {
    var changed = false;
    final existingPaths = _songs.map((song) => song.filePath).toSet();

    for (final filePath in filePaths) {
      if (existingPaths.add(filePath)) {
        _songs.add(Song.fromFilePath(filePath));
        changed = true;
      }
    }

    if (changed) {
      notifyListeners();
    }
  }

  void setCurrentSong(Song? song) {
    if (_currentSong?.id == song?.id) {
      return;
    }

    _currentSong = song;
    notifyListeners();
  }

  void updateCurrentSongDuration(Duration duration) {
    final current = _currentSong;
    if (current == null || duration <= Duration.zero) {
      return;
    }

    final index = _songs.indexWhere((song) => song.id == current.id);
    if (index == -1) {
      return;
    }

    if (_songs[index].duration == duration) {
      return;
    }

    final updated = _songs[index].copyWith(duration: duration);
    _songs[index] = updated;
    _currentSong = updated;
    notifyListeners();
  }

  int indexOf(Song song) {
    return _songs.indexWhere((candidate) => candidate.id == song.id);
  }
}
