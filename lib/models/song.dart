class Song {
  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.filePath,
    this.duration,
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
      artist: 'Unknown Artist',
      album: 'Unknown Album',
      filePath: filePath,
    );
  }

  final String id;
  final String title;
  final String artist;
  final String album;
  final String filePath;
  final Duration? duration;

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? filePath,
    Duration? duration,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      filePath: filePath ?? this.filePath,
      duration: duration ?? this.duration,
    );
  }
}

String _fileNameFromPath(String path) {
  return path.split(RegExp(r'[\\/]')).last;
}
