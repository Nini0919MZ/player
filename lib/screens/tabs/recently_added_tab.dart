import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../../providers/audio_provider.dart';
import '../../../widgets/song_list_tile.dart';
import '../../../widgets/smart_artwork.dart';
import '../../../widgets/count_banner.dart';

class RecentlyAddedTab extends StatelessWidget {
  const RecentlyAddedTab({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);

    // Sort songs by dateAdded descending (most recent first)
    final songs = List<SongModel>.from(audioProvider.allSongs)
      ..sort((a, b) {
        final da = a.dateAdded ?? 0;
        final db = b.dateAdded ?? 0;
        return db.compareTo(da);
      });

    // Show at most 100 most recent songs
    final recent = songs.take(100).toList();

    if (recent.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.new_releases_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('No hay canciones recientes', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      children: [
        CountBanner(count: recent.length, label: 'Añadidas Recientemente'),
        Expanded(
          child: ListView.builder(
            itemCount: recent.length,
      itemBuilder: (context, index) {
        final song = recent[index];
        final isSelected = audioProvider.currentSong?.id == song.id;
        return SongListTile(
          song: song,
          isSelected: isSelected,
          onTap: () => audioProvider.playPlaylist(recent, index),
        );
      },
    ),
        ),
      ],
    );
  }
}
