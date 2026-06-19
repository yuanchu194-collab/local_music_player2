import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/songs_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Songs], daos: [SongDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

@DriftAccessor(tables: [Songs])
class SongDao extends DatabaseAccessor<AppDatabase> with _$SongDaoMixin {
  SongDao(super.db);

  Future<List<SongRecord>> getAllSongs() {
    return (select(
      songs,
    )..orderBy([(song) => OrderingTerm.asc(song.createdAt)])).get();
  }

  Future<SongRecord?> findByFilePath(String filePath) {
    return (select(
      songs,
    )..where((song) => song.filePath.equals(filePath))).getSingleOrNull();
  }

  Future<int> insertSong(SongsCompanion song) {
    return into(songs).insert(song, mode: InsertMode.insertOrIgnore);
  }

  Future<void> updateImportedSong({
    required int id,
    required String title,
    required String artist,
    required String album,
    required bool isAvailable,
  }) async {
    await (update(songs)..where((song) => song.id.equals(id))).write(
      SongsCompanion(
        title: Value(title),
        artist: Value(artist),
        album: Value(album),
        isAvailable: Value(isAvailable),
      ),
    );
  }

  Future<void> updateAvailability({
    required int id,
    required bool isAvailable,
  }) async {
    await (update(songs)..where((song) => song.id.equals(id))).write(
      SongsCompanion(isAvailable: Value(isAvailable)),
    );
  }

  Future<void> updateDuration({
    required int id,
    required int durationMs,
  }) async {
    await (update(songs)..where((song) => song.id.equals(id))).write(
      SongsCompanion(durationMs: Value(durationMs)),
    );
  }

  Future<void> markPlayed(int id) async {
    final song = await (select(
      songs,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (song == null) {
      return;
    }

    await (update(songs)..where((row) => row.id.equals(id))).write(
      SongsCompanion(
        playCount: Value(song.playCount + 1),
        lastPlayedAt: Value(DateTime.now()),
      ),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final supportDirectory = await getApplicationSupportDirectory();
    await supportDirectory.create(recursive: true);

    final file = File(p.join(supportDirectory.path, 'melodybox.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
