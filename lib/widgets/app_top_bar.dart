import 'package:flutter/material.dart';

class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.title,
    required this.searchController,
    required this.onSearchChanged,
    required this.onImport,
  });

  final String title;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 760;

        final searchField = SizedBox(
          width: isNarrow ? double.infinity : 360,
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: '搜索歌曲、歌手、专辑',
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8E4)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8E4)),
              ),
            ),
          ),
        );

        final importButton = FilledButton.icon(
          onPressed: onImport,
          icon: const Icon(Icons.audio_file_rounded),
          label: const Text('导入音乐'),
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              searchField,
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: importButton),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            searchField,
            const SizedBox(width: 12),
            importButton,
          ],
        );
      },
    );
  }
}
