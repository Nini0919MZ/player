import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/audio_provider.dart';
import '../../services/state_persistence.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Configuración', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(0),
        children: [
          // ─── Sección: Pestañas ─────────────────────────────────────────
          _SectionHeader(label: 'Pestañas visibles'),
          _TabsSelector(audioProvider: audioProvider),

          const SizedBox(height: 8),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 8),

          // ─── Sección: Reproducción ─────────────────────────────────────
          _SectionHeader(label: 'Reproducción'),
          SwitchListTile(
            title: const Text('Modo automático', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Activa el modo automático (cambia orientación)',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            value: audioProvider.isAutoModeEnabled,
            onChanged: (v) => audioProvider.setAutoMode(v),
            activeThumbColor: Colors.tealAccent,
            activeTrackColor: Colors.teal.withAlpha(100),
          ),
          SwitchListTile(
            title: const Text('Epicentro habilitado', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Aplica el efecto epicentro al audio',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            value: audioProvider.isEpicenterEnabled,
            onChanged: (v) => audioProvider.toggleEpicenter(),
            activeThumbColor: Colors.tealAccent,
            activeTrackColor: Colors.teal.withAlpha(100),
          ),

          const SizedBox(height: 8),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 8),

          // ─── Sección: Biblioteca ───────────────────────────────────────
          _SectionHeader(label: 'Biblioteca'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton.icon(
              onPressed: () async {
                final result = await audioProvider.refreshLibrary();
                if (!context.mounted) return;
                final msg = (result == null || !result.hasChanges)
                    ? 'Biblioteca ya actualizada.'
                    : 'Biblioteca actualizada con cambios.';
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
              },
              icon: const Icon(Icons.refresh, color: Colors.tealAccent),
              label: const Text('Refrescar biblioteca', style: TextStyle(color: Colors.tealAccent)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.teal),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: OutlinedButton.icon(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF222222),
                    title: const Text('Restablecer epicentro',
                        style: TextStyle(color: Colors.white)),
                    content: const Text('¿Deseas restablecer los parámetros del epicentro?',
                        style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar')),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Restablecer',
                              style: TextStyle(color: Colors.redAccent))),
                    ],
                  ),
                );
                if (ok == true) {
                  await audioProvider.resetEpicenterSettingsToDefault();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Parámetros restablecidos'),
                          behavior: SnackBarBehavior.floating));
                }
              },
              icon: const Icon(Icons.restore, color: Colors.orangeAccent),
              label: const Text('Restablecer epicentro', style: TextStyle(color: Colors.orangeAccent)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.orange),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────────
// Header de sección
// ────────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Colors.tealAccent,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────────
// Selector de pestañas: lista reordenable + toggles
// ────────────────────────────────────────────────────────────────────────────────
class _TabsSelector extends StatefulWidget {
  final AudioProvider audioProvider;
  const _TabsSelector({required this.audioProvider});

  @override
  State<_TabsSelector> createState() => _TabsSelectorState();
}

class _TabsSelectorState extends State<_TabsSelector> {
  static const _allTabs = StatePersistence.allAvailableTabs;

  static const _tabMeta = <String, _TabMeta>{
    'folders':        _TabMeta('Carpetas',          Icons.folder_outlined),
    'songs':          _TabMeta('Canciones',         Icons.music_note_outlined),
    'favorites':      _TabMeta('Favoritos',         Icons.favorite_border),
    'albums':         _TabMeta('Álbumes',           Icons.album_outlined),
    'artists':        _TabMeta('Artistas',          Icons.people_outline),
    'playlists':      _TabMeta('Listas de reproducción', Icons.queue_music_outlined),
    'recently_added': _TabMeta('Añadido recientemente', Icons.new_releases_outlined),
  };

  late List<String> _enabled;

  @override
  void initState() {
    super.initState();
    _enabled = List.from(widget.audioProvider.enabledTabs);
  }

  bool _isEnabled(String id) => _enabled.contains(id);

  void _toggle(String id) {
    setState(() {
      if (_isEnabled(id)) {
        if (_enabled.length <= 1) return; // at least 1 must remain
        _enabled.remove(id);
      } else {
        // Add in default order position
        final defaultPos = _allTabs.indexOf(id);
        int insertAt = _enabled.length;
        for (int i = 0; i < _enabled.length; i++) {
          if (_allTabs.indexOf(_enabled[i]) > defaultPos) {
            insertAt = i;
            break;
          }
        }
        _enabled.insert(insertAt, id);
      }
    });
    widget.audioProvider.setEnabledTabs(List.from(_enabled));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Text(
            'Activa o desactiva las secciones que verás en la barra de pestañas.',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
        ..._allTabs.map((id) {
          final meta = _tabMeta[id]!;
          final enabled = _isEnabled(id);
          final isLast = enabled && _enabled.length == 1;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: enabled
                  ? const Color(0xFF1E3A3A)
                  : const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: enabled ? Colors.tealAccent.withAlpha(100) : Colors.white10,
                width: 1,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              leading: Icon(
                meta.icon,
                color: enabled ? Colors.tealAccent : Colors.grey,
                size: 22,
              ),
              title: Text(
                meta.label,
                style: TextStyle(
                  color: enabled ? Colors.white : Colors.grey,
                  fontWeight: enabled ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              trailing: Switch(
                value: enabled,
                onChanged: isLast ? null : (_) => _toggle(id),
                activeThumbColor: Colors.tealAccent,
                activeTrackColor: Colors.teal.withAlpha(100),
                inactiveTrackColor: Colors.white12,
                inactiveThumbColor: Colors.grey,
              ),
              onTap: isLast ? null : () => _toggle(id),
            ),
          );
        }),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white38, size: 14),
              const SizedBox(width: 6),
              Text(
                '${_enabled.length} pestañas activas',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabMeta {
  final String label;
  final IconData icon;
  const _TabMeta(this.label, this.icon);
}
