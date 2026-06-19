class Song {
  Song({
    required this.id,
    this.databaseId,
    required this.title,
    required this.artist,
    required this.album,
    required this.filePath,
    this.duration,
    this.isFavorite = false,
    this.playCount = 0,
    DateTime? createdAt,
    this.lastPlayedAt,
    this.isAvailable = true,
  }) : createdAt = createdAt ?? DateTime.now();

  Song.withCreatedAt({
    required this.id,
    this.databaseId,
    required this.title,
    required this.artist,
    required this.album,
    required this.filePath,
    this.duration,
    this.isFavorite = false,
    this.playCount = 0,
    required this.createdAt,
    this.lastPlayedAt,
    this.isAvailable = true,
  });

  factory Song.fromFilePath(String filePath) {
    final fileName = _fileNameFromPath(filePath);
    final extensionIndex = fileName.lastIndexOf('.');
    final title = extensionIndex > 0
        ? fileName.substring(0, extensionIndex)
        : fileName;

    return Song(
      id: filePath,
      title: title,
      artist: '未知艺术家',
      album: '未知专辑',
      filePath: filePath,
      createdAt: DateTime.now(),
    );
  }

  final String id;
  final int? databaseId;
  final String title;
  final String artist;
  final String album;
  final String filePath;
  final Duration? duration;
  final bool isFavorite;
  final int playCount;
  final DateTime createdAt;
  final DateTime? lastPlayedAt;
  final bool isAvailable;

  Song copyWith({
    String? id,
    int? databaseId,
    String? title,
    String? artist,
    String? album,
    String? filePath,
    Duration? duration,
    bool? isFavorite,
    int? playCount,
    DateTime? createdAt,
    DateTime? lastPlayedAt,
    bool? isAvailable,
  }) {
    return Song.withCreatedAt(
      id: id ?? this.id,
      databaseId: databaseId ?? this.databaseId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      filePath: filePath ?? this.filePath,
      duration: duration ?? this.duration,
      isFavorite: isFavorite ?? this.isFavorite,
      playCount: playCount ?? this.playCount,
      createdAt: createdAt ?? this.createdAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}

String _fileNameFromPath(String path) {
  return path.split(RegExp(r'[\\/]')).last;
}
