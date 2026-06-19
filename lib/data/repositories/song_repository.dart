import 'dart:io';

import 'package:drift/drift.dart';

import '../../models/song.dart';
import '../db/app_database.dart' as db;

abstract interface class SongRepositoryBase {
  Future<List<Song>> loadSongs();

  Future<List<Song>> importFiles(Iterable<String> filePaths);

  Future<void> updateDuration(Song song, Duration duration);

  Future<void> setFavorite(Song song, bool isFavorite);

  Future<void> markPlayed(Song song);

  Future<void> dispose();
}

class SongRepository implements SongRepositoryBase {
  SongRepository(this._database);

  final db.AppDatabase _database;

  db.SongDao get _songDao => _database.songDao;

  @override
  Future<List<Song>> loadSongs() async {
    final records = await _songDao.getAllSongs();

    for (final record in records) {
      final exists = File(record.filePath).existsSync();
      if (record.isAvailable != exists) {
        await _songDao.updateAvailability(id: record.id, isAvailable: exists);
      }
    }

    final refreshedRecords = await _songDao.getAllSongs();
    return refreshedRecords.map(_songFromRecord).toList();
  }

  @override
  Future<List<Song>> importFiles(Iterable<String> filePaths) async {
    final uniquePaths = filePaths.toSet();

    for (final filePath in uniquePaths) {
      final song = Song.fromFilePath(filePath);
      final isAvailable = File(filePath).existsSync();
      final existingRecord = await _songDao.findByFilePath(filePath);

      if (existingRecord == null) {
        await _songDao.insertSong(
          db.SongsCompanion.insert(
            title: song.title,
            artist: song.artist,
            album: song.album,
            filePath: song.filePath,
            createdAt: DateTime.now(),
            isAvailable: Value(isAvailable),
          ),
        );
      } else {
        await _songDao.updateImportedSong(
          id: existingRecord.id,
          title: song.title,
          artist: song.artist,
          album: song.album,
          isAvailable: isAvailable,
        );
      }
    }

    return loadSongs();
  }

  @override
  Future<void> updateDuration(Song song, Duration duration) async {
    final databaseId = song.databaseId;
    if (databaseId == null || duration <= Duration.zero) {
      return;
    }

    await _songDao.updateDuration(
      id: databaseId,
      durationMs: duration.inMilliseconds,
    );
  }

  @override
  Future<void> setFavorite(Song song, bool isFavorite) async {
    final databaseId = song.databaseId;
    if (databaseId == null) {
      return;
    }

    await _songDao.updateFavorite(id: databaseId, isFavorite: isFavorite);
  }

  @override
  Future<void> markPlayed(Song song) async {
    final databaseId = song.databaseId;
    if (databaseId == null) {
      return;
    }

    await _songDao.markPlayed(databaseId);
  }

  @override
  Future<void> dispose() {
    return _database.close();
  }

  Song _songFromRecord(db.SongRecord record) {
    return Song(
      id: record.id.toString(),
      databaseId: record.id,
      title: record.title,
      artist: record.artist,
      album: record.album,
      filePath: record.filePath,
      duration: record.durationMs > 0
          ? Duration(milliseconds: record.durationMs)
          : null,
      isFavorite: record.isFavorite,
      playCount: record.playCount,
      createdAt: record.createdAt,
      lastPlayedAt: record.lastPlayedAt,
      isAvailable: record.isAvailable,
    );
  }
}
