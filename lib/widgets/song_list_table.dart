import 'package:flutter/material.dart';

import '../models/song.dart';

class SongListTable extends StatelessWidget {
  const SongListTable({
    super.key,
    required this.songs,
    required this.currentSong,
    required this.isLoading,
    required this.onSongTap,
    required this.onFavoriteToggle,
    this.emptyMessage = '暂无歌曲',
  });

  final List<Song> songs;
  final Song? currentSong;
  final bool isLoading;
  final ValueChanged<Song> onSongTap;
  final ValueChanged<Song> onFavoriteToggle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE3EAE6)),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : songs.isEmpty
          ? Center(child: Text(emptyMessage))
          : Column(
              children: [
                const _HeaderRow(),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    itemCount: songs.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      return _SongRow(
                        index: index,
                        song: song,
                        isCurrent: currentSong?.id == song.id,
                        onFavoriteToggle: () => onFavoriteToggle(song),
                        onTap: () => onSongTap(song),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final showAlbum = constraints.maxWidth >= 720;
        final showArtist = constraints.maxWidth >= 560;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              SizedBox(width: 44, child: Text('#', style: style)),
              Expanded(flex: 4, child: Text('歌曲标题', style: style)),
              if (showArtist)
                Expanded(flex: 2, child: Text('歌手', style: style)),
              if (showAlbum) Expanded(flex: 2, child: Text('专辑', style: style)),
              SizedBox(width: 86, child: Text('时长', style: style)),
              SizedBox(width: 56, child: Text('喜欢', style: style)),
            ],
          ),
        );
      },
    );
  }
}

class _SongRow extends StatelessWidget {
  const _SongRow({
    required this.index,
    required this.song,
    required this.isCurrent,
    required this.onFavoriteToggle,
    required this.onTap,
  });

  final int index;
  final Song song;
  final bool isCurrent;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAvailable = song.isAvailable;

    return Material(
      color: isCurrent
          ? colorScheme.primaryContainer.withValues(alpha: 0.42)
          : Colors.white,
      child: InkWell(
        onTap: isAvailable ? onTap : null,
        child: Opacity(
          opacity: isAvailable ? 1 : 0.48,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showAlbum = constraints.maxWidth >= 720;
              final showArtist = constraints.maxWidth >= 560;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      child: Icon(
                        _leadingIcon,
                        size: 19,
                        color: isCurrent
                            ? colorScheme.primary
                            : colorScheme.outline,
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Tooltip(
                        message: song.filePath,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: isCurrent
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                            if (!showArtist) ...[
                              const SizedBox(height: 2),
                              Text(
                                song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (showArtist)
                      Expanded(
                        flex: 2,
                        child: Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (showAlbum)
                      Expanded(
                        flex: 2,
                        child: Text(
                          song.album,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    SizedBox(
                      width: 86,
                      child: Text(
                        isAvailable
                            ? _formatDuration(song.duration)
                            : 'Missing',
                        textAlign: TextAlign.left,
                      ),
                    ),
                    SizedBox(
                      width: 56,
                      child: IconButton(
                        onPressed: onFavoriteToggle,
                        tooltip: song.isFavorite ? '取消收藏' : '收藏',
                        icon: Icon(
                          song.isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: song.isFavorite
                              ? colorScheme.primary
                              : colorScheme.outline,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  IconData get _leadingIcon {
    if (!song.isAvailable) {
      return Icons.error_outline_rounded;
    }

    return isCurrent ? Icons.volume_up_rounded : Icons.music_note_rounded;
  }
}

String _formatDuration(Duration? duration) {
  if (duration == null || duration <= Duration.zero) {
    return '--';
  }

  final totalSeconds = duration.inSeconds;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
