import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:audiotags/audiotags.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/audio_provider.dart';
import '../services/state_persistence.dart';
import '../utils/title_utils.dart';

void showOptionsMenu(BuildContext context, AudioProvider audioProvider) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF222222),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return _OptionsMenuContent(audioProvider: audioProvider);
    },
  );
}

class _OptionsMenuContent extends StatelessWidget {
  final AudioProvider audioProvider;
  const _OptionsMenuContent({required this.audioProvider});

  @override
  Widget build(BuildContext context) {
    final song = audioProvider.currentSong;
    if (song == null) return const SizedBox.shrink();

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          ListTile(
            leading:
                const Icon(Icons.edit_outlined, color: Colors.white, size: 28),
            title: const Text("Editor de etiquetas",
                style: TextStyle(color: Colors.white, fontSize: 18)),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                  context: context,
                  builder: (context) =>
                      _EditTagDialog(provider: audioProvider));
            },
          ),
          ListTile(
            leading: const Icon(Icons.graphic_eq_rounded,
                color: Colors.white, size: 28),
            title: const Text("Ajustes de Epicentro",
                style: TextStyle(color: Colors.white, fontSize: 18)),
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFF222222),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => _EpicenterSettingsSheet(
                  audioProvider: audioProvider,
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline,
                color: Colors.redAccent, size: 28),
            title: const Text("Eliminar del dispositivo",
                style: TextStyle(color: Colors.redAccent, fontSize: 18)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteDialog(context, audioProvider);
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, AudioProvider provider) {
    final song = provider.currentSong;
    if (song == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        title: const Text("Confirmar eliminación",
            style: TextStyle(color: Colors.white)),
        content: Text(
            "¿Eliminar '${TitleUtils.getDisplayTitle(song)}' del dispositivo?",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text("Cancelar", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await provider.deleteSong(song);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? "Archivo eliminado correctamente."
                          : "Error al eliminar. Verifica los permisos.",
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: success ? Colors.black87 : Colors.red,
                  ),
                );
              }
            },
            child: const Text("Eliminar",
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _EpicenterSettingsSheet extends StatefulWidget {
  final AudioProvider audioProvider;

  const _EpicenterSettingsSheet({required this.audioProvider});

  @override
  State<_EpicenterSettingsSheet> createState() =>
      _EpicenterSettingsSheetState();
}

class _EpicenterSettingsSheetState extends State<_EpicenterSettingsSheet> {
  late double _sweepFreq;
  late double _width;
  late double _intensity;
  late double _balance;
  late double _volume;

  @override
  void initState() {
    super.initState();
    final provider = widget.audioProvider;
    _sweepFreq = provider.epicenterSweepFreq;
    _width = provider.epicenterWidth;
    _intensity = provider.epicenterIntensity;
    _balance = provider.epicenterBalance;
    _volume = provider.epicenterVolume;
  }

  Future<void> _resetDefaults() async {
    setState(() {
      _sweepFreq = StatePersistence.defaultEpicenterSweepFreq;
      _width = StatePersistence.defaultEpicenterWidth;
      _intensity = StatePersistence.defaultEpicenterIntensity;
      _balance = StatePersistence.defaultEpicenterBalance;
      _volume = StatePersistence.defaultEpicenterVolume;
    });
    await widget.audioProvider.resetEpicenterSettingsToDefault();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ajustes de Epicentro',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _ParamSlider(
              label: 'Sweep Freq',
              value: _sweepFreq,
              min: 27,
              max: 63,
              unit: 'Hz',
              onChanged: (value) {
                setState(() => _sweepFreq = value);
                widget.audioProvider.updateEpicenterSettings(sweepFreq: value);
              },
            ),
            _ParamSlider(
              label: 'Width',
              value: _width,
              min: 0,
              max: 100,
              unit: '%',
              onChanged: (value) {
                setState(() => _width = value);
                widget.audioProvider.updateEpicenterSettings(width: value);
              },
            ),
            _ParamSlider(
              label: 'Intensity',
              value: _intensity,
              min: 0,
              max: 100,
              unit: '%',
              onChanged: (value) {
                setState(() => _intensity = value);
                widget.audioProvider.updateEpicenterSettings(intensity: value);
              },
            ),
            _ParamSlider(
              label: 'Balance',
              value: _balance,
              min: 0,
              max: 100,
              unit: '%',
              onChanged: (value) {
                setState(() => _balance = value);
                widget.audioProvider.updateEpicenterSettings(balance: value);
              },
            ),
            _ParamSlider(
              label: 'Volume',
              value: _volume,
              min: 0,
              max: 100,
              unit: '%',
              onChanged: (value) {
                setState(() => _volume = value);
                widget.audioProvider.updateEpicenterSettings(volume: value);
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetDefaults,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white30),
                    ),
                    child: const Text(
                      'Por defecto',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ParamSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String unit;
  final ValueChanged<double> onChanged;

  const _ParamSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
            Text(
              '${value.toStringAsFixed(0)} $unit',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ─── Full ID3 Tag Editor ──────────────────────────────────────────────────────

class _EditTagDialog extends StatefulWidget {
  final AudioProvider provider;
  const _EditTagDialog({required this.provider});

  @override
  State<_EditTagDialog> createState() => _EditTagDialogState();
}

class _EditTagDialogState extends State<_EditTagDialog> {
  late final TextEditingController _title;
  late final TextEditingController _album;
  late final TextEditingController _artist;
  late final TextEditingController _albumArtist;
  late final TextEditingController _composer;
  late final TextEditingController _genre;
  late final TextEditingController _year;
  late final TextEditingController _track;
  File? _newCoverFile;
  Uint8List? _existingCoverBytes;
  List<Picture> _existingPictures = [];

  @override
  void initState() {
    super.initState();
    final song = widget.provider.currentSong!;
    final artistText =
        (song.artist == "<unknown>" || song.artist == null) ? "" : song.artist!;
    _title = TextEditingController(text: TitleUtils.getDisplayTitle(song));
    _album = TextEditingController(text: song.album ?? "");
    _artist = TextEditingController(text: artistText);
    _albumArtist = TextEditingController();
    _composer = TextEditingController();
    _genre = TextEditingController(text: song.genre ?? "");
    _year = TextEditingController();
    _track = TextEditingController(text: song.track?.toString() ?? "");

    _loadExistingTags(song.data);
  }

  Future<void> _loadExistingTags(String path) async {
    try {
      final tag = await AudioTags.read(path);
      if (tag != null && mounted) {
        setState(() {
          if (tag.year != null && _year.text.isEmpty) {
            _year.text = tag.year.toString();
          }
          if (tag.genre != null && _genre.text.isEmpty) {
            _genre.text = tag.genre!;
          }
          if (tag.pictures.isNotEmpty) {
            _existingPictures = tag.pictures;
            _existingCoverBytes = tag.pictures.first.bytes;
          }
        });
      }
    } catch (e) {
      debugPrint('Error reading existing tags: $e');
    }
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _album,
      _artist,
      _albumArtist,
      _composer,
      _genre,
      _year,
      _track
    ]) c.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _newCoverFile = File(picked.path));
  }

  Future<void> _save() async {
    Navigator.pop(context);
    try {
      final song = widget.provider.currentSong!;

      List<Picture> pics = [];
      Uint8List? coverBytesForCache;

      if (_newCoverFile != null) {
        coverBytesForCache = await _newCoverFile!.readAsBytes();
        pics = [
          Picture(
            bytes: coverBytesForCache,
            pictureType: PictureType.coverFront,
            mimeType: MimeType.jpeg,
          )
        ];
      } else if (_existingPictures.isNotEmpty) {
        // PRESERVAR CARÁTULA EXISTENTE: Reinyectar las fotos leídas de las etiquetas
        pics = _existingPictures;
        coverBytesForCache = _existingCoverBytes;
      } else {
        // Fallback por si la lectura asíncrona no había terminado aún
        final tagRead = await AudioTags.read(song.data);
        if (tagRead != null && tagRead.pictures.isNotEmpty) {
          pics = tagRead.pictures;
          coverBytesForCache = pics.first.bytes;
        }
      }

      final tag = Tag(
        title: _title.text.trim().isEmpty ? null : _title.text.trim(),
        album: _album.text.trim().isEmpty ? null : _album.text.trim(),
        artist: _artist.text.trim().isEmpty ? null : _artist.text.trim(),
        genre: _genre.text.trim().isEmpty ? null : _genre.text.trim(),
        year: int.tryParse(_year.text),
        pictures: pics,
      );

      // 1. Escribir metadatos en el archivo físico
      await AudioTags.write(song.data, tag);

      // 2. Actualizar AudioProvider, MediaItem y notificación del sistema en tiempo real
      await widget.provider.updateSongMetadata(
        song,
        newTitle: _title.text.trim().isEmpty ? song.title : _title.text.trim(),
        newArtist: _artist.text.trim().isEmpty
            ? (song.artist ?? 'Artista Desconocido')
            : _artist.text.trim(),
        newAlbum: _album.text.trim().isEmpty ? song.album : _album.text.trim(),
        newGenre: _genre.text.trim().isEmpty ? song.genre : _genre.text.trim(),
        newCoverBytes: coverBytesForCache,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Etiquetas guardadas y actualizadas en vivo.",
                style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Error al guardar: $e",
                style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red));
      }
    }
  }

  Widget _field(TextEditingController ctrl, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24)),
          focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? coverImageProvider;
    if (_newCoverFile != null) {
      coverImageProvider = FileImage(_newCoverFile!);
    } else if (_existingCoverBytes != null) {
      coverImageProvider = MemoryImage(_existingCoverBytes!);
    }

    return AlertDialog(
      backgroundColor: const Color(0xFF2A2A2A),
      title: const Text("Editor de etiquetas",
          style: TextStyle(color: Colors.white, fontSize: 22)),
      contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cover art picker
              GestureDetector(
                onTap: _pickCover,
                child: Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                    image: coverImageProvider != null
                        ? DecorationImage(
                            image: coverImageProvider, fit: BoxFit.cover)
                        : null,
                  ),
                  child: coverImageProvider == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                  color: Colors.white60, size: 36),
                              SizedBox(height: 4),
                              Text("Cambiar imagen",
                                  style: TextStyle(
                                      color: Colors.white60, fontSize: 11),
                                  textAlign: TextAlign.center),
                            ])
                      : null,
                ),
              ),
              _field(_title, "Título"),
              _field(_album, "Álbum"),
              _field(_artist, "Artista"),
              _field(_albumArtist, "Artista del álbum"),
              _field(_composer, "Compositor"),
              _field(_genre, "Género"),
              _field(_year, "Año"),
              _field(_track,
                  "Track (4 para la pista 4 o 2004 para CD 2, pista 4)"),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text("cancelar", style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[700]),
          child: const Text("Guardar", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
