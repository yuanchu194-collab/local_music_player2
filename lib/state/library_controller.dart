import 'package:flutter/foundation.dart';

import '../data/repositories/song_repository.dart';
import '../models/song.dart';

class LibraryController extends ChangeNotifier {
  LibraryController({required this.songRepository});

  final SongRepositoryBase songRepository;
  final List<Song> _songs = [];

  Song? _currentSong;
  bool _isLoading = false;

  List<Song> get songs => List.unmodifiable(_songs);

  List<Song> get availableSongs =>
      _songs.where((song) => song.isAvailable).toList(growable: false);

  Song? get currentSong => _currentSong;

  bool get hasSongs => _songs.isNotEmpty;

  bool get hasAvailableSongs => availableSongs.isNotEmpty;

  bool get isLoading => _isLoading;

  Future<void> loadLibrary() async {
    _isLoading = true;
    notifyListeners();

    final loadedSongs = await songRepository.loadSongs();
    _songs
      ..clear()
      ..addAll(loadedSongs);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> importFiles(Iterable<String> filePaths) async {
    final importedSongs = await songRepository.importFiles(filePaths);
    _songs
      ..clear()
      ..addAll(importedSongs);
    notifyListeners();
  }

  Future<void> setCurrentSong(Song? song) async {
    final isSameSong = _currentSong?.id == song?.id;
    if (!isSameSong) {
      _currentSong = song;
      notifyListeners();
    }

    if (song != null) {
      await songRepository.markPlayed(song);
    }

    if (isSameSong) {
      return;
    }
  }

  Future<void> updateCurrentSongDuration(Duration duration) async {
    final current = _currentSong;
    if (current == null || duration <= Duration.zero) {
      return;
    }

    final index = _songs.indexWhere((song) => song.id == current.id);
    if (index == -1 || _songs[index].duration == duration) {
      return;
    }

    await songRepository.updateDuration(current, duration);

    final updated = _songs[index].copyWith(duration: duration);
    _songs[index] = updated;
    _currentSong = updated;
    notifyListeners();
  }

  int indexOfAvailableSong(Song song) {
    return availableSongs.indexWhere((candidate) => candidate.id == song.id);
  }
}
