import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  late final AudioPlayer _player;

  VoidCallback? onToggleFavorite;
  FutureOr<void> Function()? onEpicenterToggleRequested;
  FutureOr<void> Function()? onPreviousFolderRequested;
  FutureOr<void> Function()? onNextFolderRequested;
  bool Function()? isEpicenterEnabledProvider;
  FutureOr<void> Function()? onTrackCompleted;
  FutureOr<void> Function()? onPlayPauseRequested;
  FutureOr<void> Function()? onStopRequested;
  FutureOr<void> Function()? onPreviousRequested;
  FutureOr<void> Function()? onNextRequested;
  Future<List<MediaItem>> Function(String parentMediaId,
      [Map<String, dynamic>? options])? onGetChildrenRequested;
  Future<MediaItem?> Function(String mediaId)? onGetMediaItemRequested;
  FutureOr<void> Function(String mediaId, [Map<String, dynamic>? extras])?
      onPlayFromMediaIdRequested;
  bool _isAdvancing = false;
  bool _androidAutoModeActive = false;
  Timer? _debounceTimer;

  MyAudioHandler() {
    _player = AudioPlayer();
    _init();
  }

  Future<int?> getAndroidAudioSessionId() async {
    return _player.androidAudioSessionId;
  }

  Future<void> _init() async {
    // 1. Propagate player state to notification
    _player.playbackEventStream.listen(_broadcastState);

    // 2. Update MediaItem when song changes
    _player.currentIndexStream.listen((index) {
      if (index != null && index < queue.value.length) {
        mediaItem.add(queue.value[index]);
      }
    });

    // 3. Fallback completion detection: Position >= Duration
    _player.positionStream.listen((position) {
      final duration = _player.duration;
      if (duration != null &&
          position >= duration &&
          position.inMilliseconds > 0) {
        _handleCompletionSignal();
      }
    });

    // 4. Listen to standard completed state as well
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _handleCompletionSignal();
      }
    });
  }

  void _handleCompletionSignal() {
    debugPrint(
      '[AudioHandler] completion signal: '
      'queue=${queue.value.length}, '
      'index=${_player.currentIndex}, '
      'hasNext=${_player.hasNext}, '
      'processingState=${_player.processingState}',
    );
    unawaited(_triggerNextTrackSafe());
  }

  Future<void> _triggerNextTrackSafe() async {
    if (_isAdvancing) return;
    _isAdvancing = true;

    try {
      if (_player.hasNext) {
        debugPrint(
          '[AudioHandler] completion -> seekToNext: '
          'from=${_player.currentIndex}, queue=${queue.value.length}',
        );
        await _player.seekToNext();
        return;
      }

      final completionAction = onTrackCompleted;
      if (completionAction != null) {
        debugPrint(
          '[AudioHandler] completion -> onTrackCompleted: '
          'queue=${queue.value.length}, index=${_player.currentIndex}',
        );
        await completionAction();
        return;
      }

      await stopDirect();
    } catch (e, stackTrace) {
      debugPrint('Error handling track completion: $e');
      debugPrintStack(stackTrace: stackTrace);
      try {
        await stopDirect();
      } catch (stopError) {
        debugPrint('Error stopping after completion failure: $stopError');
      }
    } finally {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        _isAdvancing = false;
      });
    }
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: _controlsForContext(playing),
      systemActions: const {},
      androidCompactActionIndices:
          _androidAutoModeActive ? const [1, 2, 3] : const [0, 1, 2],
      processingState: const {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[_player.processingState] ??
          AudioProcessingState.idle,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    ));
  }

  List<MediaControl> _controlsForContext(bool playing) {
    final playPause = playing ? MediaControl.pause : MediaControl.play;

    if (!_androidAutoModeActive) {
      return [
        MediaControl.skipToPrevious,
        playPause,
        MediaControl.skipToNext,
        MediaControl.stop,
      ];
    }

    final isEpicenterEnabled = isEpicenterEnabledProvider?.call() ?? false;
    return [
      MediaControl.custom(
        androidIcon: 'drawable/ic_folder_previous',
        label: 'Folder anterior',
        name: 'previous_folder',
      ),
      MediaControl.skipToPrevious,
      playPause,
      MediaControl.skipToNext,
      MediaControl.custom(
        androidIcon: 'drawable/ic_folder_next',
        label: 'Folder siguiente',
        name: 'next_folder',
      ),
      MediaControl.custom(
        androidIcon: 'drawable/ic_epicenter',
        label: isEpicenterEnabled ? 'Epicentro ON' : 'Epicentro',
        name: 'epicenter_toggle',
      ),
    ];
  }

  void _markAndroidAutoActive() {
    if (_androidAutoModeActive) return;
    _androidAutoModeActive = true;
    _broadcastState(_player.playbackEvent);
  }

  @override
  Future<void> play() async {
    final action = onPlayPauseRequested;
    if (action != null) {
      await action();
      return;
    }
    await playDirect();
  }

  @override
  Future<void> pause() async {
    final action = onPlayPauseRequested;
    if (action != null) {
      await action();
      return;
    }
    await pauseDirect();
  }

  @override
  Future<void> stop() async {
    final action = onStopRequested;
    if (action != null) {
      await action();
      return;
    }
    await stopDirect();
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'toggle_favorite' && onToggleFavorite != null) {
      onToggleFavorite!();
      return;
    } else if (name == 'epicenter_toggle' &&
        onEpicenterToggleRequested != null) {
      await onEpicenterToggleRequested!();
      _broadcastState(_player.playbackEvent);
      return;
    } else if (name == 'previous_folder' && onPreviousFolderRequested != null) {
      await onPreviousFolderRequested!();
      return;
    } else if (name == 'next_folder' && onNextFolderRequested != null) {
      await onNextFolderRequested!();
      return;
    }
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    final action = onNextRequested;
    if (action != null) {
      await action();
      return;
    }
    await skipToNextDirect();
  }

  @override
  Future<void> skipToPrevious() async {
    final action = onPreviousRequested;
    if (action != null) {
      await action();
      return;
    }
    await skipToPreviousDirect();
  }

  @override
  Future<void> skipToQueueItem(int index) =>
      _player.seek(Duration.zero, index: index);

  @override
  Future<List<MediaItem>> getChildren(String parentMediaId,
      [Map<String, dynamic>? options]) {
    _markAndroidAutoActive();
    final action = onGetChildrenRequested;
    if (action != null) return action(parentMediaId, options);
    return super.getChildren(parentMediaId, options);
  }

  @override
  Future<MediaItem?> getMediaItem(String mediaId) {
    _markAndroidAutoActive();
    final action = onGetMediaItemRequested;
    if (action != null) return action(mediaId);
    return super.getMediaItem(mediaId);
  }

  @override
  Future<void> playFromMediaId(String mediaId,
      [Map<String, dynamic>? extras]) async {
    _markAndroidAutoActive();
    final action = onPlayFromMediaIdRequested;
    if (action != null) {
      await action(mediaId, extras);
      return;
    }
    await super.playFromMediaId(mediaId, extras);
  }

  @override
  Future<void> updateQueue(List<MediaItem> queue) async {
    this.queue.add(queue);
  }

  Future<void> loadPlaylist(List<MediaItem> newQueue, int initialIndex,
      [Duration? initialPosition]) async {
    await replacePlaylist(
      newQueue,
      initialIndex,
      initialPosition ?? Duration.zero,
      shouldPlay: initialPosition == null,
    );
  }

  Future<void> replacePlaylist(
    List<MediaItem> newQueue,
    int initialIndex,
    Duration initialPosition, {
    required bool shouldPlay,
  }) async {
    // Rebuild the native playlist entirely to prevent stale source caching.
    await _player.stop();

    if (newQueue.isEmpty) {
      queue.add([]);
      mediaItem.add(null);
      return;
    }

    final safeIndex = initialIndex.clamp(0, newQueue.length - 1);
    queue.add(newQueue);
    mediaItem.add(newQueue[safeIndex]);
    debugPrint(
      '[AudioHandler] replacePlaylist: '
      'queue=${newQueue.length}, initialIndex=$safeIndex, '
      'shouldPlay=$shouldPlay',
    );

    // Explicitly set the initial index down at the native source creation!
    await _player.setAudioSources(
      newQueue.map(_createAudioSource).toList(),
      initialIndex: safeIndex,
      initialPosition: initialPosition,
    );

    if (shouldPlay) {
      await _player.play();
    } else {
      _broadcastState(_player.playbackEvent);
    }
  }

  AudioSource _createAudioSource(MediaItem item) {
    final source = item.extras?['source'] as String? ??
        item.extras?['songPath'] as String? ??
        item.id;
    return AudioSource.uri(
      source.startsWith('/') ? Uri.file(source) : Uri.parse(source),
      tag: item,
    );
  }

  Future<void> playDirect() => _player.play();

  Future<void> pauseDirect() => _player.pause();

  Future<void> stopDirect() async {
    await _player.stop();
    await super.stop();
  }

  Future<void> skipToNextDirect() => _player.seekToNext();

  Future<void> skipToPreviousDirect() => _player.seekToPrevious();

  AudioPlayer get player => _player;
}
