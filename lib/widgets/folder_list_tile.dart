import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../../providers/audio_provider.dart';
import '../../theme/app_theme.dart';

class FolderListTile extends StatelessWidget {
  final String folderName;
  final String folderPath;
  final List<SongModel> songs;
  final VoidCallback onTap;

  const FolderListTile({
    super.key,
    required this.folderName,
    required this.folderPath,
    required this.songs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final songCount = songs.length;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      leading: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: const Icon(Icons.folder, color: Colors.grey, size: 30),
      ),
      title: Text(
        folderName,
        style: const TextStyle(
          color: AppTheme.textMain,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          '$songCount Canciones',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
        color: AppTheme.surfaceColor,
        onSelected: (value) {
          final audioProvider =
              Provider.of<AudioProvider>(context, listen: false);
          if (value == 'reproducir') {
            audioProvider.playFolderSongs(folderPath, songs, 0);
          } else if (value == 'anadir') {
            audioProvider.addAllToQueue(songs);
          } else if (value == 'delete') {
            _showDeleteConfirmation(context, audioProvider);
          }
        },
        itemBuilder: (context) => const <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'reproducir',
            child: Text('Reproducir'),
          ),
          PopupMenuItem<String>(
            value: 'anadir',
            child: Text('Anadir a lista'),
          ),
          PopupMenuDivider(),
          PopupMenuItem<String>(
            value: 'delete',
            child: Text('Borrar carpeta', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    AudioProvider audioProvider,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Eliminar carpeta',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Seguro que quieres borrar la carpeta "$folderName" de la lista? No se borran los archivos fisicos.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCELAR',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
          TextButton(
            onPressed: () {
              audioProvider.deleteFolder(folderPath);
              Navigator.pop(context);
            },
            child: const Text(
              'ELIMINAR',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
