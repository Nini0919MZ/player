import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/audio_provider.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Configuración', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Modo automático'),
            subtitle: const Text('Activa el modo automático (cambia orientación)'),
            value: audioProvider.isAutoModeEnabled,
            onChanged: (v) => audioProvider.setAutoMode(v),
            activeColor: Colors.teal,
          ),
          SwitchListTile(
            title: const Text('Epicentro habilitado'),
            subtitle: const Text('Aplica el efecto epicentro al audio'),
            value: audioProvider.isEpicenterEnabled,
            onChanged: (v) => audioProvider.toggleEpicenter(),
            activeColor: Colors.teal,
          ),

          const SizedBox(height: 20),

          Text('Número de pestañas (2-6)', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              final val = 2 + i; // 2..6
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: OutlinedButton(
                    onPressed: () async {
                      await audioProvider.setTabCount(val);
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pestañas establecidas a $val')));
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: audioProvider.tabCount == val ? Colors.teal : Colors.white24),
                      backgroundColor: audioProvider.tabCount == val ? Colors.white12 : null,
                    ),
                    child: Text('$val', style: TextStyle(color: Colors.white)),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Restablecer parámetros'),
                  content: const Text('¿Deseas restablecer los parámetros de epicentro por defecto?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restablecer')),
                  ],
                ),
              );
              if (result == true) {
                await audioProvider.resetEpicenterSettingsToDefault();
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Parámetros restablecidos')));
              }
            },
            child: const Text('Restablecer epicentro'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              await audioProvider.refreshLibrary();
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Refrescada la biblioteca')));
            },
            child: const Text('Refrescar biblioteca'),
          ),
        ],
      ),
    );
  }
}
