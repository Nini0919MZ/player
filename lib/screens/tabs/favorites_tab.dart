import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/audio_provider.dart';
import '../../widgets/song_list_tile.dart';
import '../../widgets/count_banner.dart';

class FavoritesTab extends StatelessWidget {
  const FavoritesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final favoriteSongs = audioProvider.allSongs.where((s) => audioProvider.isFavorite(s.id)).toList();

    return Column(
      children: [
        CountBanner(count: favoriteSongs.length, label: 'Favoritos'),
        Expanded(
          child: ListView.builder(
            itemCount: favoriteSongs.length,
            itemBuilder: (context, index) {
              final song = favoriteSongs[index];
              final isSelected = audioProvider.currentSong?.id == song.id;
              return SongListTile(
                song: song,
                isSelected: isSelected,
                onTap: () => audioProvider.playPlaylist(favoriteSongs, index),
              );
            },
          ),
        ),
      ],
    );
  }
}
