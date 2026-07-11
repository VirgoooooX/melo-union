import 'package:provider_contract/provider_contract.dart';

int _entrySequence = 0;

String createPlaybackQueueEntryId() {
  final micros = DateTime.now().toUtc().microsecondsSinceEpoch;
  return 'queue-$micros-${_entrySequence++}';
}

final class PlaybackQueueEntry {
  const PlaybackQueueEntry({
    required this.entryId,
    required this.track,
    required this.queuedAt,
  });

  final String entryId;
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

  int? get nextIndex {
    final candidate = currentIndex + 1;
    return candidate >= 0 && candidate < entries.length ? candidate : null;
  }

  PlaybackQueueEntry? get next {
    final index = nextIndex;
    return index == null ? null : entries[index];
  }

  bool isCurrentEntry(String entryId) => current?.entryId == entryId;

  bool isNextEntry(String entryId) => next?.entryId == entryId;

  PlaybackQueueState replaceWith(List<SourceTrack> tracks) {
    final nextEntries = [
      for (final track in tracks)
        PlaybackQueueEntry(
          entryId: createPlaybackQueueEntryId(),
          track: track,
          queuedAt: DateTime.now().toUtc(),
        ),
    ];
    return PlaybackQueueState(
      entries: List.unmodifiable(nextEntries),
      currentIndex: nextEntries.isEmpty ? -1 : 0,
    );
  }

  PlaybackQueueState append(SourceTrack track) {
    final nextEntries = [
      ...entries,
      PlaybackQueueEntry(
        entryId: createPlaybackQueueEntryId(),
        track: track,
        queuedAt: DateTime.now().toUtc(),
      ),
    ];
    return PlaybackQueueState(
      entries: List.unmodifiable(nextEntries),
      currentIndex: currentIndex == -1 ? 0 : currentIndex,
    );
  }

  @Deprecated('Use append to make queue-tail semantics explicit.')
  PlaybackQueueState enqueue(SourceTrack track) => append(track);

  PlaybackQueueState insertNext(SourceTrack track) {
    if (current == null) return append(track);
    final nextEntries = [...entries]..insert(
        currentIndex + 1,
        PlaybackQueueEntry(
          entryId: createPlaybackQueueEntryId(),
          track: track,
          queuedAt: DateTime.now().toUtc(),
        ),
      );
    return PlaybackQueueState(
      entries: List.unmodifiable(nextEntries),
      currentIndex: currentIndex,
    );
  }

  PlaybackQueueState moveEntryNext(String entryId) {
    final sourceIndex = entries.indexWhere((entry) => entry.entryId == entryId);
    if (sourceIndex == -1 ||
        sourceIndex == currentIndex ||
        sourceIndex == nextIndex) {
      return this;
    }
    final mutable = [...entries];
    final movingEntry = mutable.removeAt(sourceIndex);
    var adjustedCurrentIndex = currentIndex;
    if (sourceIndex < currentIndex) adjustedCurrentIndex--;
    mutable.insert(adjustedCurrentIndex + 1, movingEntry);
    return PlaybackQueueState(
      entries: List.unmodifiable(mutable),
      currentIndex: adjustedCurrentIndex,
    );
  }

  PlaybackQueueState moveEntry({required int from, required int to}) {
    if (from < 0 || from >= entries.length || to < 0 || to >= entries.length) {
      return this;
    }
    if (from == to) return this;
    final currentId = current?.entryId;
    final mutable = [...entries];
    final moving = mutable.removeAt(from);
    mutable.insert(to, moving);
    return PlaybackQueueState(
      entries: List.unmodifiable(mutable),
      currentIndex: currentId == null
          ? -1
          : mutable.indexWhere((entry) => entry.entryId == currentId),
    );
  }

  PlaybackQueueState removeAt(int index) {
    if (index < 0 || index >= entries.length) return this;
    final nextEntries = [...entries]..removeAt(index);
    if (nextEntries.isEmpty) return PlaybackQueueState.empty();

    final nextIndex = switch (currentIndex) {
      -1 => 0,
      final current when index < current => current - 1,
      final current when index == current && current >= nextEntries.length =>
        nextEntries.length - 1,
      final current => current,
    };
    return PlaybackQueueState(
      entries: List.unmodifiable(nextEntries),
      currentIndex: nextIndex,
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
