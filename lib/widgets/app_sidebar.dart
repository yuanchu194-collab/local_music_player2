import 'package:flutter/material.dart';

enum AppSection { home, library, favorites, playlists, settings }

extension AppSectionDetails on AppSection {
  String get label {
    return switch (this) {
      AppSection.home => '首页',
      AppSection.library => '音乐库',
      AppSection.favorites => '我喜欢',
      AppSection.playlists => '播放列表',
      AppSection.settings => '设置',
    };
  }

  IconData get icon {
    return switch (this) {
      AppSection.home => Icons.home_rounded,
      AppSection.library => Icons.library_music_rounded,
      AppSection.favorites => Icons.favorite_border_rounded,
      AppSection.playlists => Icons.queue_music_rounded,
      AppSection.settings => Icons.settings_rounded,
    };
  }
}

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.selectedSection,
    required this.onSectionSelected,
    required this.totalSongs,
    required this.availableSongs,
  });

  final AppSection selectedSection;
  final ValueChanged<AppSection> onSectionSelected;
  final int totalSongs;
  final int availableSongs;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 244,
      color: const Color(0xFFF1F7F3),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.music_note_rounded,
                  color: colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MelodyBox',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '本地音乐播放器',
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
          const SizedBox(height: 28),
          for (final section in AppSection.values) ...[
            _SidebarItem(
              section: section,
              isSelected: selectedSection == section,
              onTap: () => onSectionSelected(section),
            ),
            const SizedBox(height: 6),
          ],
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              border: Border.all(color: const Color(0xFFE1E9E4)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.folder_rounded,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '本地音乐库',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '$availableSongs / $totalSongs 可播放',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: totalSongs == 0 ? 0 : availableSongs / totalSongs,
                    minHeight: 6,
                    backgroundColor: colorScheme.primary.withValues(
                      alpha: 0.10,
                    ),
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

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.section,
    required this.isSelected,
    required this.onTap,
  });

  final AppSection section;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected
          ? colorScheme.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                section.icon,
                size: 22,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  section.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
