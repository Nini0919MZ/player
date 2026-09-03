import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import '../models/duration_state.dart';
import '../providers/audio_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/smart_artwork.dart';
import '../widgets/marquee_text.dart';
import '../utils/title_utils.dart';
import '../widgets/options_menu.dart';
import '../widgets/queue_bottom_sheet.dart';
import '../widgets/song_info_modal.dart';
import '../screens/artist_detail_screen.dart';
import '../screens/album_detail_screen.dart';
import '../services/state_persistence.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final song = audioProvider.currentSong;

    if (song == null) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: Material(
        color: AppTheme.surfaceColor,
        child: InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              backgroundColor: AppTheme.surfaceColor,
              shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(30))),
              builder: (context) => const _PlayerModalContent(),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: SmartArtwork(
                        albumId: song.id,
                        songPath: song.data,
                        type: ArtworkType.AUDIO,
                        size: 50,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MarqueeText(
                            text: TitleUtils.getDisplayTitle(song),
                            style: const TextStyle(
                              color: AppTheme.textMain,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            height: 20,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.artist ?? "Desconocido",
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        audioProvider.isFavorite(song.id)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: audioProvider.isFavorite(song.id)
                            ? Colors.redAccent
                            : AppTheme.textSecondary,
                        size: 24,
                      ),
                      onPressed: () => audioProvider.toggleFavorite(song),
                    ),
                    StreamBuilder<bool>(
                      stream: audioProvider.player.playingStream,
                      builder: (context, snapshot) {
                        final isPlaying = snapshot.data ?? false;
                        return IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: AppTheme.textMain,
                            size: 32,
                          ),
                          onPressed: audioProvider.togglePlayPause,
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.queue_music,
                          color: AppTheme.textSecondary, size: 24),
                      onPressed: () {
                        showQueueBottomSheet(context);
                      },
                      tooltip: "Cola de reproducción",
                    ),
                  ],
                ),
              ),
              StreamBuilder<DurationState>(
                stream: audioProvider.durationStateStream,
                builder: (context, snapshot) {
                  final position = snapshot.data?.position ?? Duration.zero;
                  final total = snapshot.data?.total ?? Duration.zero;

                  double progressValue = 0.0;
                  if (total.inMilliseconds > 0) {
                    progressValue =
                        position.inMilliseconds / total.inMilliseconds;
                  }

                  return LinearProgressIndicator(
                    value: progressValue.clamp(0.0, 1.0),
                    backgroundColor: Colors.transparent,
                    color: AppTheme.primaryColor,
                    minHeight: 2,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerModalContent extends StatefulWidget {
  const _PlayerModalContent();

  @override
  State<_PlayerModalContent> createState() => _PlayerModalContentState();
}

class _PlayerModalContentState extends State<_PlayerModalContent> {
  bool _modoAuto = false;
  bool _epicentro = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final modoAuto = await StatePersistence.loadAutoMode();
    final epicentro = await StatePersistence.loadEpicenterEnabled();
    if (!mounted) return;
    setState(() {
      _modoAuto = modoAuto;
      _epicentro = epicentro;
    });

    final audioProvider = context.read<AudioProvider>();
    await audioProvider.setAutoMode(modoAuto);
    if (audioProvider.isEpicenterEnabled != epicentro) {
      await audioProvider.toggleEpicenter();
    }
  }

  Future<void> _toggleModoAuto(AudioProvider audioProvider) async {
    final nextValue = !_modoAuto;
    setState(() => _modoAuto = nextValue);
    await StatePersistence.saveAutoMode(nextValue);
    await audioProvider.setAutoMode(nextValue);
  }

  Future<void> _toggleEpicentro(AudioProvider audioProvider) async {
    final nextValue = !_epicentro;
    setState(() => _epicentro = nextValue);
    await StatePersistence.saveEpicenterEnabled(nextValue);
    if (audioProvider.isEpicenterEnabled != nextValue) {
      await audioProvider.toggleEpicenter();
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final song = audioProvider.currentSong;

    if (song == null) return const SizedBox.shrink();

    final artista = TitleUtils.getDisplayArtist(song.artist);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down,
              color: Colors.white, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "REPRODUCIENDO DESDE",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () {
                final albumSongs = audioProvider.allSongs
                    .where(
                      (s) =>
                          TitleUtils.getAlbumKey(s) ==
                          TitleUtils.getAlbumKey(song),
                    )
                    .toList();
                if (albumSongs.isEmpty) return;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AlbumDetailScreen(
                      albumName: _resolveAlbumLabel(song),
                      albumId: song.albumId ?? 0,
                      songs: albumSongs,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _resolveAlbumLabel(song),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 26),
            color: const Color(0xFF252525),
            onSelected: (value) async {
              if (value == 'info_archivo' && context.mounted) {
                showSongInfo(context, song);
                return;
              }
              if (value == 'editor_etiquetas' && context.mounted) {
                showEditTagDialog(context, audioProvider, song: song);
                return;
              }
              if (value == 'modo_auto') {
                await _toggleModoAuto(audioProvider);
                return;
              }
              if (value == 'epicentro') {
                await _toggleEpicentro(audioProvider);
                return;
              }
              if (value == 'eliminar' && context.mounted) {
                showDeleteDialog(context, audioProvider, song);
                return;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'info_archivo',
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 20, color: Colors.white),
                    SizedBox(width: 10),
                    Text('Información de archivo',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'editor_etiquetas',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20, color: Colors.white),
                    SizedBox(width: 10),
                    Text('Editor de etiquetas',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'modo_auto',
                child: Row(
                  children: [
                    Icon(
                      Icons.directions_car_filled_rounded,
                      size: 20,
                      color: _modoAuto ? Colors.greenAccent : Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _modoAuto ? 'Modo Auto: ON' : 'Modo Auto: OFF',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'epicentro',
                child: Row(
                  children: [
                    Icon(
                      Icons.graphic_eq_rounded,
                      size: 20,
                      color: _epicentro ? Colors.greenAccent : Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _epicentro ? 'Epicentro: ON' : 'Epicentro: OFF',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              if (_epicentro)
                PopupMenuItem(
                  enabled: false,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: StatefulBuilder(
                    builder: (context, setItemState) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Intensidad',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 2.0,
                                    thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 6.0),
                                    overlayShape: const RoundSliderOverlayShape(
                                        overlayRadius: 14.0),
                                  ),
                                  child: Slider(
                                    value: audioProvider.epicenterIntensity,
                                    min: 0,
                                    max: 100,
                                    activeColor: Colors.greenAccent,
                                    inactiveColor: Colors.white24,
                                    onChanged: (v) {
                                      audioProvider.updateEpicenterSettings(
                                          intensity: v);
                                      setItemState(() {});
                                    },
                                  ),
                                ),
                              ),
                              Text(
                                '${audioProvider.epicenterIntensity.toInt()}%',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              const PopupMenuItem(
                value: 'eliminar',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline,
                        size: 20, color: Colors.redAccent),
                    SizedBox(width: 10),
                    Text('Eliminar del dispositivo',
                        style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[900]!.withValues(alpha: 0.8),
              const Color(0xFF121212),
            ],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const Spacer(flex: 1),
              Expanded(
                flex: 10,
                child: ClipRect(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onDoubleTap: () {
                        final currentPos = audioProvider.player.position;
                        audioProvider.player
                            .seek(currentPos + const Duration(seconds: 10));
                      },
                      child: Center(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final artworkSize =
                                constraints.biggest.shortestSide;
                            return SizedBox.square(
                              dimension: artworkSize,
                              child: SmartArtwork(
                                albumId: song.id,
                                songPath: song.data,
                                type: ArtworkType.AUDIO,
                                size: artworkSize,
                                borderRadius: BorderRadius.circular(
                                    12), // Bordes redondeados sutiles para mejorar la estética
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Material(
                type: MaterialType.transparency,
                child: SizedBox(
                  height: 48,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.shuffle,
                          color: audioProvider.isShuffle
                              ? Colors.greenAccent
                              : Colors.white60,
                          size: 24,
                        ),
                        onPressed: () => audioProvider.toggleShuffle(),
                      ),
                      IconButton(
                        key: const ValueKey('now_playing_folder_previous'),
                        icon: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(Icons.folder_outlined,
                                color: Colors.white60, size: 24),
                            Transform.translate(
                              offset: const Offset(4, 4),
                              child: const Icon(Icons.remove,
                                  color: Colors.white, size: 12),
                            ),
                          ],
                        ),
                        onPressed: () async {
                          await audioProvider.playPreviousFolder();
                        },
                        tooltip: "Carpeta anterior",
                      ),
                      IconButton(
                        icon: Icon(
                          audioProvider.loopMode == LoopMode.one
                              ? Icons.repeat_one
                              : Icons.repeat,
                          color: audioProvider.loopMode != LoopMode.off
                              ? Colors.greenAccent
                              : Colors.white60,
                          size: 24,
                        ),
                        onPressed: audioProvider.toggleLoop,
                      ),
                      IconButton(
                        key: const ValueKey('now_playing_folder_next'),
                        icon: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(Icons.folder_outlined,
                                color: Colors.white60, size: 24),
                            Transform.translate(
                              offset: const Offset(4, 4),
                              child: const Icon(Icons.add,
                                  color: Colors.white, size: 12),
                            ),
                          ],
                        ),
                        onPressed: () async {
                          await audioProvider.playNextFolder();
                        },
                        tooltip: "Carpeta siguiente",
                      ),
                      IconButton(
                        icon: const Icon(Icons.queue_music,
                            color: Colors.white60, size: 24),
                        onPressed: () => showQueueBottomSheet(context),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 2),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => showSongInfo(context, song),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.75,
                            height: 45,
                            child: MarqueeText(
                              text: TitleUtils.getDisplayTitle(song),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                              velocity: 35.0,
                              gap: 60.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () {
                            final artistName =
                                TitleUtils.getDisplayArtist(song.artist);
                            final artistKey =
                                TitleUtils.getArtistKey(song.artist);
                            final artistSongs = audioProvider.allSongs
                                .where((s) =>
                                    TitleUtils.getArtistKey(s.artist) ==
                                    artistKey)
                                .toList();
                            if (artistSongs.isEmpty) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ArtistDetailScreen(
                                    artistName: artistName, songs: artistSongs),
                              ),
                            );
                          },
                          child: Text(
                            artista,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.left,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      audioProvider.isFavorite(song.id)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: audioProvider.isFavorite(song.id)
                          ? Colors.redAccent
                          : Colors.white,
                      size: 32,
                    ),
                    onPressed: () => audioProvider.toggleFavorite(song),
                  ),
                ],
              ),
              const Spacer(flex: 2),
              StreamBuilder<DurationState>(
                stream: audioProvider.durationStateStream,
                builder: (context, snapshot) {
                  final durationState = snapshot.data;
                  final progress = durationState?.position ?? Duration.zero;
                  final total = durationState?.total ?? Duration.zero;

                  return Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6),
                          overlayShape:
                              const RoundSliderOverlayShape(overlayRadius: 14),
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white24,
                          thumbColor: Colors.white,
                        ),
                        child: Slider(
                          value: progress.inMilliseconds.toDouble(),
                          max: total.inMilliseconds.toDouble().clamp(
                              progress.inMilliseconds.toDouble(),
                              double.infinity),
                          onChanged: (value) {
                            audioProvider.player
                                .seek(Duration(milliseconds: value.toInt()));
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(progress),
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12),
                            ),
                            Text(
                              _formatDuration(total),
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const Spacer(flex: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_10_rounded,
                        color: Colors.white, size: 38),
                    onPressed: () {
                      final currentPos = audioProvider.player.position;
                      audioProvider.player
                          .seek(currentPos - const Duration(seconds: 10));
                    },
                    tooltip: "-10s",
                  ),
                  GestureDetector(
                    onTap: () => audioProvider.previousSmart(),
                    child: const Icon(Icons.skip_previous_rounded,
                        color: Colors.white, size: 65),
                  ),
                  StreamBuilder<bool>(
                    stream: audioProvider.player.playingStream,
                    builder: (context, snapshot) {
                      final isPlaying = snapshot.data ?? false;
                      return Container(
                        width: 85,
                        height: 85,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(0, 5)),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.black,
                            size: 55,
                          ),
                          onPressed: audioProvider.togglePlayPause,
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded,
                        color: Colors.white, size: 65),
                    onPressed: audioProvider.next,
                    padding: EdgeInsets.zero,
                  ),
                  IconButton(
                    icon: const Icon(Icons.forward_10_rounded,
                        color: Colors.white, size: 38),
                    onPressed: () {
                      final currentPos = audioProvider.player.position;
                      audioProvider.player
                          .seek(currentPos + const Duration(seconds: 10));
                    },
                    tooltip: "+10s",
                  ),
                ],
              ),
              const Spacer(flex: 2),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 15.0),
                  child: Text(
                    path.dirname(song.data),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        letterSpacing: 0.5),
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) return "0:00";
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '${duration.inMinutes}:$seconds';
  }

  String _resolveAlbumLabel(dynamic song) {
    return TitleUtils.getDisplayAlbum(song as SongModel);
  }
}
