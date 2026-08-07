import 'package:flutter/material.dart';
import '../../widgets/count_banner.dart';

class PlaylistsTab extends StatelessWidget {
  const PlaylistsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CountBanner(count: 0, label: 'Playlists'),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.queue_music, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('No hay playlists aún', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
