import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/playback_mode.dart';
import '../models/song.dart';
import '../services/audio_player_service.dart';

class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({
    super.key,
    required this.audioPlayerService,
    required this.currentSong,
    required this.canPlayback,
    required this.hasCurrentSong,
    required this.isSeeking,
    required this.seekPreviewMs,
    required this.onSeekStart,
    required this.onSeekChanged,
    required this.onSeekEnd,
    required this.onTogglePlayPause,
    required this.onPrevious,
    required this.onNext,
    required this.onCyclePlaybackMode,
    required this.onVolumeChanged,
  });

  final AudioPlayerServiceBase audioPlayerService;
  final Song? currentSong;
  final bool canPlayback;
  final bool hasCurrentSong;
  final bool isSeeking;
  final double seekPreviewMs;
  final ValueChanged<double> onSeekStart;
  final ValueChanged<double> onSeekChanged;
  final ValueChanged<double> onSeekEnd;
  final Future<void> Function(bool isPlaying) onTogglePlayPause;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onCyclePlaybackMode;
  final ValueChanged<double> onVolumeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE3EAE6))),
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 20,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: StreamBuilder<bool>(
        stream: audioPlayerService.playingStream,
        initialData: false,
        builder: (context, playingSnapshot) {
          final isPlaying = playingSnapshot.data ?? false;

          return StreamBuilder<PlaybackMode>(
            stream: audioPlayerService.playbackModeStream,
            initialData: audioPlayerService.playbackMode,
            builder: (context, playbackModeSnapshot) {
              final playbackMode =
                  playbackModeSnapshot.data ?? PlaybackMode.sequence;

              return StreamBuilder<double>(
                stream: audioPlayerService.volumeStream,
                initialData: audioPlayerService.volume,
                builder: (context, volumeSnapshot) {
                  final volume = volumeSnapshot.data ?? 1;

                  return StreamBuilder<Duration>(
                    stream: audioPlayerService.durationStream,
                    initialData: Duration.zero,
                    builder: (context, durationSnapshot) {
                      final duration = durationSnapshot.data ?? Duration.zero;

                      return StreamBuilder<Duration>(
                        stream: audioPlayerService.positionStream,
                        initialData: Duration.zero,
                        builder: (context, positionSnapshot) {
                          final position =
                              positionSnapshot.data ?? Duration.zero;
                          final maxMs = math.max(
                            duration.inMilliseconds.toDouble(),
                            1,
                          );
                          final rawValue = isSeeking
                              ? seekPreviewMs
                              : position.inMilliseconds.toDouble();
                          final sliderValue = rawValue
                              .clamp(0, maxMs)
                              .toDouble();

                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final compact = constraints.maxWidth < 860;

                              return Row(
                                children: [
                                  _NowPlaying(song: currentSong),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Wrap(
                                          alignment: WrapAlignment.center,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          spacing: 10,
                                          runSpacing: 6,
                                          children: [
                                            IconButton(
                                              onPressed: hasCurrentSong
                                                  ? onPrevious
                                                  : null,
                                              tooltip: '上一首',
                                              icon: const Icon(
                                                Icons.skip_previous_rounded,
                                              ),
                                            ),
                                            FilledButton(
                                              onPressed: canPlayback
                                                  ? () => onTogglePlayPause(
                                                      isPlaying,
                                                    )
                                                  : null,
                                              style: FilledButton.styleFrom(
                                                shape: const CircleBorder(),
                                                padding: const EdgeInsets.all(
                                                  16,
                                                ),
                                              ),
                                              child: Icon(
                                                isPlaying
                                                    ? Icons.pause_rounded
                                                    : Icons.play_arrow_rounded,
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: hasCurrentSong
                                                  ? onNext
                                                  : null,
                                              tooltip: '下一首',
                                              icon: const Icon(
                                                Icons.skip_next_rounded,
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: onCyclePlaybackMode,
                                              tooltip: _playbackModeLabel(
                                                playbackMode,
                                              ),
                                              icon: Icon(
                                                _playbackModeIcon(playbackMode),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            SizedBox(
                                              width: 42,
                                              child: Text(
                                                _formatDuration(
                                                  Duration(
                                                    milliseconds: sliderValue
                                                        .round(),
                                                  ),
                                                ),
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                              ),
                                            ),
                                            Expanded(
                                              child: Slider(
                                                value: sliderValue,
                                                min: 0,
                                                max: maxMs.toDouble(),
                                                onChangeStart: hasCurrentSong
                                                    ? onSeekStart
                                                    : null,
                                                onChanged: hasCurrentSong
                                                    ? onSeekChanged
                                                    : null,
                                                onChangeEnd: hasCurrentSong
                                                    ? onSeekEnd
                                                    : null,
                                              ),
                                            ),
                                            SizedBox(
                                              width: 42,
                                              child: Text(
                                                _formatNullableDuration(
                                                  duration,
                                                ),
                                                textAlign: TextAlign.right,
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!compact) ...[
                                    const SizedBox(width: 18),
                                    _VolumeControl(
                                      volume: volume,
                                      onChanged: onVolumeChanged,
                                    ),
                                  ],
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _NowPlaying extends StatelessWidget {
  const _NowPlaying({required this.song});

  final Song? song;

  @override
  Widget build(BuildContext context) {
    final currentSong = song;
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 240,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.music_note_rounded,
              color: colorScheme.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentSong?.title ?? '暂无播放',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  currentSong?.artist ?? '选择音乐开始播放',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VolumeControl extends StatelessWidget {
  const _VolumeControl({required this.volume, required this.onChanged});

  final double volume;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Row(
        children: [
          const Icon(Icons.volume_up_rounded, size: 20),
          Expanded(
            child: Slider(
              value: volume.clamp(0, 1).toDouble(),
              min: 0,
              max: 1,
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 42,
            child: Text(
              '${(volume * 100).round()}%',
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatNullableDuration(Duration? duration) {
  if (duration == null || duration <= Duration.zero) {
    return '--';
  }

  return _formatDuration(duration);
}

String _formatDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

String _playbackModeLabel(PlaybackMode mode) {
  return switch (mode) {
    PlaybackMode.sequence => '顺序播放',
    PlaybackMode.repeatAll => '列表循环',
    PlaybackMode.repeatOne => '单曲循环',
    PlaybackMode.shuffle => '随机播放',
  };
}

IconData _playbackModeIcon(PlaybackMode mode) {
  return switch (mode) {
    PlaybackMode.sequence => Icons.trending_flat_rounded,
    PlaybackMode.repeatAll => Icons.repeat_rounded,
    PlaybackMode.repeatOne => Icons.repeat_one_rounded,
    PlaybackMode.shuffle => Icons.shuffle_rounded,
  };
}
