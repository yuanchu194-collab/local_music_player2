import 'package:drift/drift.dart';

@DataClassName('SongRecord')
class Songs extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get title => text()();

  TextColumn get artist => text()();

  TextColumn get album => text()();

  TextColumn get filePath => text().unique()();

  IntColumn get durationMs => integer().withDefault(const Constant(0))();

  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  IntColumn get playCount => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get lastPlayedAt => dateTime().nullable()();

  BoolColumn get isAvailable => boolean().withDefault(const Constant(true))();
}
