import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import 'data/db/app_database.dart';
import 'data/repositories/song_repository.dart';
import 'models/song.dart';
import 'services/audio_player_service.dart';
import 'state/library_controller.dart';
import 'widgets/app_sidebar.dart';
import 'widgets/app_top_bar.dart';
import 'widgets/mini_player_bar.dart';
import 'widgets/song_list_table.dart';
import 'widgets/stat_card.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const MelodyBoxApp());
}

class MelodyBoxApp extends StatefulWidget {
  const MelodyBoxApp({super.key, this.audioPlayerService, this.songRepository});

  final AudioPlayerServiceBase? audioPlayerService;
  final SongRepositoryBase? songRepository;

  @override
  State<MelodyBoxApp> createState() => _MelodyBoxAppState();
}

class _MelodyBoxAppState extends State<MelodyBoxApp> {
  late final AudioPlayerServiceBase _audioPlayerService;
  late final SongRepositoryBase _songRepository;

  @override
  void initState() {
    super.initState();
    _audioPlayerService = widget.audioPlayerService ?? AudioPlayerService();
    _songRepository = widget.songRepository ?? SongRepository(AppDatabase());
  }

  @override
  void dispose() {
    _audioPlayerService.dispose();
    _songRepository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MelodyBox',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF22A96B)),
        scaffoldBackgroundColor: const Color(0xFFF6F8F7),
        useMaterial3: true,
      ),
      home: MainShellPage(
        audioPlayerService: _audioPlayerService,
        songRepository: _songRepository,
      ),
    );
  }
}

class MainShellPage extends StatefulWidget {
  const MainShellPage({
    super.key,
    required this.audioPlayerService,
    required this.songRepository,
  });

  final AudioPlayerServiceBase audioPlayerService;
  final SongRepositoryBase songRepository;

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  late final LibraryController _libraryController;
  late final TextEditingController _searchController;
  late final StreamSubscription<Song?> _currentSongSubscription;
  late final StreamSubscription<Duration> _durationSubscription;

  AppSection _selectedSection = AppSection.home;
  String _searchQuery = '';
  String? _errorMessage;
  bool _isSeeking = false;
  double _seekPreviewMs = 0;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _libraryController = LibraryController(
      songRepository: widget.songRepository,
    );
    unawaited(_libraryController.loadLibrary());
    _currentSongSubscription = widget.audioPlayerService.currentSongStream
        .listen((song) => unawaited(_libraryController.setCurrentSong(song)));
    _durationSubscription = widget.audioPlayerService.durationStream.listen(
      (duration) =>
          unawaited(_libraryController.updateCurrentSongDuration(duration)),
    );
  }

  @override
  void dispose() {
    _currentSongSubscription.cancel();
    _durationSubscription.cancel();
    _searchController.dispose();
    _libraryController.dispose();
    super.dispose();
  }

  Future<void> _pickAudioFiles() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['mp3', 'flac', 'wav'],
        allowMultiple: true,
      );

      final paths = result?.files
          .map((file) => file.path)
          .whereType<String>()
          .toList();
      if (paths == null || paths.isEmpty) {
        return;
      }

      await _libraryController.importFiles(paths);
      _selectSection(AppSection.library);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = '无法导入所选音频文件。';
      });
    }
  }

  Future<void> _playAll() async {
    final songs = _filteredSongs(availableOnly: true);
    if (songs.isEmpty) {
      return;
    }

    await _runPlaybackAction(
      () => widget.audioPlayerService.playQueue(songs: songs, startIndex: 0),
      errorMessage: '无法播放音乐库。',
    );
  }

  Future<void> _playSong(Song song) async {
    if (!song.isAvailable) {
      setState(() {
        _errorMessage = '该文件不可用，可能已被移动或删除。';
      });
      return;
    }

    final songs = _filteredSongs(availableOnly: true);
    final index = songs.indexWhere((candidate) => candidate.id == song.id);
    if (index == -1) {
      return;
    }

    await _runPlaybackAction(
      () =>
          widget.audioPlayerService.playQueue(songs: songs, startIndex: index),
      errorMessage: '无法播放这首歌。',
    );
  }

  Future<void> _togglePlayPause(bool isPlaying) async {
    final currentSong = _libraryController.currentSong;
    final songs = _filteredSongs(availableOnly: true);
    if (currentSong == null && songs.isEmpty) {
      return;
    }

    await _runPlaybackAction(() async {
      if (currentSong == null) {
        await widget.audioPlayerService.playQueue(songs: songs, startIndex: 0);
      } else if (isPlaying) {
        await widget.audioPlayerService.pause();
      } else {
        await widget.audioPlayerService.resume();
      }
    }, errorMessage: '播放失败。');
  }

  Future<void> _seekTo(double milliseconds) async {
    await _runPlaybackAction(
      () => widget.audioPlayerService.seek(
        Duration(milliseconds: milliseconds.round()),
      ),
      errorMessage: '无法调整播放进度。',
    );
  }

  Future<void> _previous() async {
    await _runPlaybackAction(
      widget.audioPlayerService.previous,
      errorMessage: '无法播放上一首。',
    );
  }

  Future<void> _next() async {
    await _runPlaybackAction(
      widget.audioPlayerService.next,
      errorMessage: '无法播放下一首。',
    );
  }

  Future<void> _cyclePlaybackMode() async {
    await _runPlaybackAction(
      widget.audioPlayerService.cyclePlaybackMode,
      errorMessage: '无法切换播放模式。',
    );
  }

  Future<void> _setVolume(double volume) async {
    await _runPlaybackAction(
      () => widget.audioPlayerService.setVolume(volume),
      errorMessage: '无法调整音量。',
    );
  }

  Future<void> _toggleFavorite(Song song) async {
    setState(() {
      _errorMessage = null;
    });

    try {
      await _libraryController.toggleFavorite(song);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = '无法更新收藏状态。';
      });
    }
  }

  Future<void> _runPlaybackAction(
    Future<void> Function() action, {
    required String errorMessage,
  }) async {
    setState(() {
      _errorMessage = null;
    });

    try {
      await action();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = errorMessage;
      });
    }
  }

  void _selectSection(AppSection section) {
    setState(() {
      _selectedSection = section;
    });
  }

  void _updateSearch(String value) {
    setState(() {
      _searchQuery = value.trim().toLowerCase();
    });
  }

  List<Song> _filteredSongs({bool availableOnly = false}) {
    final source = switch (_selectedSection) {
      AppSection.favorites => _libraryController.songs.where(
        (song) => song.isFavorite,
      ),
      _ => _libraryController.songs,
    };

    return source
        .where((song) {
          if (availableOnly && !song.isAvailable) {
            return false;
          }
          if (_searchQuery.isEmpty) {
            return true;
          }

          return song.title.toLowerCase().contains(_searchQuery) ||
              song.artist.toLowerCase().contains(_searchQuery) ||
              song.album.toLowerCase().contains(_searchQuery);
        })
        .toList(growable: false);
  }

  String get _pageTitle => _selectedSection.label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _libraryController,
        builder: (context, _) {
          final totalSongs = _libraryController.songs.length;
          final availableSongs = _libraryController.availableSongs.length;

          return Row(
            children: [
              AppSidebar(
                selectedSection: _selectedSection,
                onSectionSelected: _selectSection,
                totalSongs: totalSongs,
                availableSongs: availableSongs,
              ),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppTopBar(
                              title: _pageTitle,
                              searchController: _searchController,
                              onSearchChanged: _updateSearch,
                              onImport: _pickAudioFiles,
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 12),
                              _ErrorBanner(message: _errorMessage!),
                            ],
                            const SizedBox(height: 18),
                            Expanded(child: _buildCurrentPage()),
                          ],
                        ),
                      ),
                    ),
                    MiniPlayerBar(
                      audioPlayerService: widget.audioPlayerService,
                      currentSong: _libraryController.currentSong,
                      canPlayback: _libraryController.hasAvailableSongs,
                      hasCurrentSong:
                          _libraryController.currentSong?.isAvailable == true,
                      isSeeking: _isSeeking,
                      seekPreviewMs: _seekPreviewMs,
                      onSeekStart: (value) {
                        setState(() {
                          _isSeeking = true;
                          _seekPreviewMs = value;
                        });
                      },
                      onSeekChanged: (value) {
                        setState(() {
                          _seekPreviewMs = value;
                        });
                      },
                      onSeekEnd: (value) async {
                        setState(() {
                          _isSeeking = false;
                        });
                        await _seekTo(value);
                      },
                      onTogglePlayPause: _togglePlayPause,
                      onPrevious: _previous,
                      onNext: _next,
                      onCyclePlaybackMode: _cyclePlaybackMode,
                      onVolumeChanged: _setVolume,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCurrentPage() {
    return switch (_selectedSection) {
      AppSection.home => _HomePage(
        songs: _libraryController.songs,
        availableSongs: _libraryController.availableSongs,
        isLoading: _libraryController.isLoading,
        currentSong: _libraryController.currentSong,
        onPlayAll: _playAll,
        onSongTap: _playSong,
        onFavoriteToggle: _toggleFavorite,
      ),
      AppSection.library => _LibraryPage(
        songs: _filteredSongs(),
        currentSong: _libraryController.currentSong,
        isLoading: _libraryController.isLoading,
        onPlayAll: _playAll,
        onSongTap: _playSong,
        onFavoriteToggle: _toggleFavorite,
      ),
      AppSection.favorites => _FavoritesPage(
        songs: _filteredSongs(),
        currentSong: _libraryController.currentSong,
        isLoading: _libraryController.isLoading,
        onPlayAll: _playAll,
        onSongTap: _playSong,
        onFavoriteToggle: _toggleFavorite,
      ),
      AppSection.playlists => _PlaceholderPage(
        icon: Icons.queue_music_rounded,
        title: '播放列表',
        message: '播放列表管理会在后续阶段单独实现。',
      ),
      AppSection.settings => _PlaceholderPage(
        icon: Icons.settings_rounded,
        title: '设置',
        message: '主题、音量持久化和更多设置会在后续阶段实现。',
      ),
    };
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage({
    required this.songs,
    required this.availableSongs,
    required this.isLoading,
    required this.currentSong,
    required this.onPlayAll,
    required this.onSongTap,
    required this.onFavoriteToggle,
  });

  final List<Song> songs;
  final List<Song> availableSongs;
  final bool isLoading;
  final Song? currentSong;
  final VoidCallback onPlayAll;
  final ValueChanged<Song> onSongTap;
  final ValueChanged<Song> onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final favoriteCount = songs.where((song) => song.isFavorite).length;
    final recentSongs =
        songs.where((song) => song.lastPlayedAt != null).toList(growable: false)
          ..sort((a, b) => b.lastPlayedAt!.compareTo(a.lastPlayedAt!));

    return ListView(
      children: [
        _WelcomeCard(onPlayAll: availableSongs.isEmpty ? null : onPlayAll),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 980
                ? 4
                : constraints.maxWidth >= 720
                ? 2
                : 1;
            return GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                mainAxisExtent: 92,
              ),
              children: [
                StatCard(
                  icon: Icons.music_note_rounded,
                  label: '歌曲总数',
                  value: songs.length.toString(),
                ),
                StatCard(
                  icon: Icons.check_circle_outline_rounded,
                  label: '可播放歌曲',
                  value: availableSongs.length.toString(),
                ),
                StatCard(
                  icon: Icons.favorite_border_rounded,
                  label: '喜欢歌曲',
                  value: favoriteCount.toString(),
                ),
                StatCard(
                  icon: Icons.history_rounded,
                  label: '最近播放',
                  value: recentSongs.length.toString(),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        Text(
          '最近播放',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: SongListTable(
            songs: recentSongs.take(5).toList(growable: false),
            currentSong: currentSong,
            isLoading: isLoading,
            onSongTap: onSongTap,
            onFavoriteToggle: onFavoriteToggle,
            emptyMessage: '还没有最近播放记录。',
          ),
        ),
      ],
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.onPlayAll});

  final VoidCallback? onPlayAll;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCEBE4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '欢迎回到 MelodyBox',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '继续管理和播放你的本地音乐库。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: onPlayAll,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('播放全部'),
          ),
        ],
      ),
    );
  }
}

class _LibraryPage extends StatelessWidget {
  const _LibraryPage({
    required this.songs,
    required this.currentSong,
    required this.isLoading,
    required this.onPlayAll,
    required this.onSongTap,
    required this.onFavoriteToggle,
  });

  final List<Song> songs;
  final Song? currentSong;
  final bool isLoading;
  final VoidCallback onPlayAll;
  final ValueChanged<Song> onSongTap;
  final ValueChanged<Song> onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '共 ${songs.length} 首歌曲',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            FilledButton.icon(
              onPressed: songs.any((song) => song.isAvailable)
                  ? onPlayAll
                  : null,
              icon: const Icon(Icons.playlist_play_rounded),
              label: const Text('播放全部'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SongListTable(
            songs: songs,
            currentSong: currentSong,
            isLoading: isLoading,
            onSongTap: onSongTap,
            onFavoriteToggle: onFavoriteToggle,
            emptyMessage: '没有找到匹配的歌曲。',
          ),
        ),
      ],
    );
  }
}

class _FavoritesPage extends StatelessWidget {
  const _FavoritesPage({
    required this.songs,
    required this.currentSong,
    required this.isLoading,
    required this.onPlayAll,
    required this.onSongTap,
    required this.onFavoriteToggle,
  });

  final List<Song> songs;
  final Song? currentSong;
  final bool isLoading;
  final VoidCallback onPlayAll;
  final ValueChanged<Song> onSongTap;
  final ValueChanged<Song> onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final playableCount = songs.where((song) => song.isAvailable).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '共 ${songs.length} 首喜欢歌曲，$playableCount 首可播放',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            FilledButton.icon(
              onPressed: playableCount > 0 ? onPlayAll : null,
              icon: const Icon(Icons.playlist_play_rounded),
              label: const Text('播放全部'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SongListTable(
            songs: songs,
            currentSong: currentSong,
            isLoading: isLoading,
            onSongTap: onSongTap,
            onFavoriteToggle: onFavoriteToggle,
            emptyMessage: '还没有收藏歌曲。',
          ),
        ),
      ],
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE3EAE6)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 42, color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: colorScheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
