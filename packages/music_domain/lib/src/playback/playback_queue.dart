import 'package:provider_contract/provider_contract.dart';

final class PlaybackQueueEntry {
  const PlaybackQueueEntry({
    required this.track,
    required this.queuedAt,
  });

  final SourceTrack track;
  final DateTime queuedAt;
}

final class PlaybackQueueState {
  const PlaybackQueueState({
    required this.entries,
    required this.currentIndex,
  });

  factory PlaybackQueueState.empty() =>
      const PlaybackQueueState(entries: [], currentIndex: -1);

  final List<PlaybackQueueEntry> entries;
  final int currentIndex;

  PlaybackQueueEntry? get current =>
      currentIndex >= 0 && currentIndex < entries.length
          ? entries[currentIndex]
          : null;

  PlaybackQueueState replaceWith(List<SourceTrack> tracks) {
    final nextEntries = [
      for (final track in tracks)
        PlaybackQueueEntry(track: track, queuedAt: DateTime.now().toUtc()),
    ];
    return PlaybackQueueState(
      entries: List.unmodifiable(nextEntries),
      currentIndex: nextEntries.isEmpty ? -1 : 0,
    );
  }

  PlaybackQueueState enqueue(SourceTrack track) {
    final nextEntries = [
      ...entries,
      PlaybackQueueEntry(track: track, queuedAt: DateTime.now().toUtc()),
    ];
    return PlaybackQueueState(
      entries: List.unmodifiable(nextEntries),
      currentIndex: currentIndex == -1 ? 0 : currentIndex,
    );
  }

  PlaybackQueueState moveNext() {
    if (currentIndex == -1 || currentIndex + 1 >= entries.length) {
      return this;
    }
    return PlaybackQueueState(
      entries: entries,
      currentIndex: currentIndex + 1,
    );
  }

  PlaybackQueueState movePrevious() {
    if (currentIndex <= 0) {
      return this;
    }
    return PlaybackQueueState(
      entries: entries,
      currentIndex: currentIndex - 1,
    );
  }
}
