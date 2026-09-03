import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../utils/title_utils.dart';
import '../utils/duration_utils.dart';
import 'package:provider/provider.dart';
import 'song_info_modal.dart';
import '../providers/audio_provider.dart';

import 'smart_artwork.dart';
import '../theme/app_theme.dart';

class SongListTile extends StatelessWidget {
  final SongModel song;
  final VoidCallback onTap;
  final bool isSelected;
  final bool showTrailing;

  // Selección múltiple
  final bool isSelectionMode;
  final bool isChecked;
  final VoidCallback? onLongPress;
  final VoidCallback? onCheckChanged;

  const SongListTile({
    super.key,
    required this.song,
    required this.onTap,
    this.isSelected = false,
    this.showTrailing = true,
    this.isSelectionMode = false,
    this.isChecked = false,
    this.onLongPress,
    this.onCheckChanged,
  });

  // Bug #4 fix: usa DurationUtils que maneja correctamente horas (HH:mm:ss)
  String _formatDuration(int? milliseconds) =>
      DurationUtils.formatMilliseconds(milliseconds);

  @override
  Widget build(BuildContext context) {
    final String displayTitle = TitleUtils.getDisplayTitle(song);
    // Bug #5 fix: usa TitleUtils.getDisplayArtist para cubrir <unknown>, null, undefined, etc.
    final String displayArtist = TitleUtils.getDisplayArtist(song.artist);

    return GestureDetector(
      onLongPress: onLongPress,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        // Modo selección: muestra checkbox en lugar de artwork
        leading: isSelectionMode
            ? GestureDetector(
                onTap: onCheckChanged,
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isChecked ? AppTheme.primaryColor : Colors.transparent,
                        border: Border.all(
                          color: isChecked ? AppTheme.primaryColor : Colors.white54,
                          width: 2,
                        ),
                      ),
                      child: isChecked
                          ? const Icon(Icons.check, color: Colors.white, size: 14)
                          : null,
                    ),
                  ),
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(5.0),
                child: SmartArtwork(
                  albumId: song.id,
                  songPath: song.data,
                  type: ArtworkType.AUDIO,
                  size: 56,
                  borderRadius: BorderRadius.circular(5.0),
                ),
              ),
        title: Text(
          displayTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isChecked
                ? AppTheme.primaryColor
                : (isSelected ? AppTheme.primaryColor : Colors.white),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Text(
            "$displayArtist • ${_formatDuration(song.duration)}",
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: isSelectionMode
            ? null
            : (showTrailing
                ? PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey[500]),
                    color: const Color(0xFF222222),
                    onSelected: (value) {
                      final audioProvider =
                          Provider.of<AudioProvider>(context, listen: false);
                      if (value == 'favorito') {
                        audioProvider.toggleFavorite(song);
                      } else if (value == 'eliminar') {
                        _showDeleteDialog(context, audioProvider);
                      } else if (value == 'reproducir') {
                        audioProvider.insertNextInQueue(song);
                      } else if (value == 'encolar') {
                        audioProvider.addToQueue(song);
                      } else if (value == 'info') {
                        showSongInfo(context, song);
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'reproducir',
                        child: Text('Reproducir a continuación'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'encolar',
                        child: Text('Añadir a la cola'),
                      ),
                      PopupMenuItem<String>(
                        value: 'favorito',
                        child: Consumer<AudioProvider>(
                          builder: (context, ap, _) => Text(ap.isFavorite(song.id)
                              ? 'Quitar de favoritos'
                              : 'Añadir a favoritos'),
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'info',
                        child: Text('Información'),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'eliminar',
                        child: Text('Eliminar del dispositivo',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  )
                : null),
        onTap: isSelectionMode ? onCheckChanged : onTap,
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, AudioProvider audioProvider) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text("Eliminar canción", style: TextStyle(color: Colors.white)),
        content: Text(
          "¿Estás seguro de que quieres eliminar '${TitleUtils.getDisplayTitle(song)}' permanentemente de tu dispositivo?",
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("CANCELAR", style: TextStyle(color: AppTheme.primaryColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("ELIMINAR", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await audioProvider.deleteSong(song);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success 
                ? "Canción eliminada correctamente" 
                : "No se pudo eliminar la canción. Verifica los permisos.",
            ),
            backgroundColor: success ? Colors.green[800] : Colors.red[800],
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

}