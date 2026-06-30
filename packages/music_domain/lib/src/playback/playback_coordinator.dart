import 'package:provider_contract/provider_contract.dart';
import 'playback_queue.dart';

class PlaybackCoordinator {
  PlaybackCoordinator({
    required this.registry,
    AudioQuality defaultQuality = AudioQuality.standard,
  }) : _quality = defaultQuality;

  final StaticProviderRegistry registry;
  AudioQuality _quality;

  PlaybackQueueState _queueState = PlaybackQueueState.empty();
  PlaybackTicket? _currentTicket;
  PlaybackTicket? _nextTicket;
  Object? _currentError;

  PlaybackQueueState get queueState => _queueState;
  PlaybackTicket? get currentTicket => _currentTicket;
  PlaybackTicket? get nextTicket => _nextTicket;
  Object? get currentError => _currentError;
  AudioQuality get quality => _quality;

  set quality(AudioQuality newQuality) {
    _quality = newQuality;
    _currentTicket = null;
    _nextTicket = null;
  }

  void setQueue(List<SourceTrack> tracks) {
    _queueState = _queueState.replaceWith(tracks);
    _currentTicket = null;
    _nextTicket = null;
    _currentError = null;
  }

  void enqueue(SourceTrack track) {
    _queueState = _queueState.enqueue(track);
    _nextTicket = null;
  }

  /// Updates the [isFavorited] field of the track identified by [trackRef] in
  /// the current queue. No-op if the track is not in the queue.
  void updateFavoriteState(ProviderTrackRef trackRef, bool liked) {
    final index =
        _queueState.entries.indexWhere((entry) => entry.track.ref == trackRef);
    if (index == -1) return;
    final entries = [..._queueState.entries];
    final oldEntry = entries[index];
    entries[index] = PlaybackQueueEntry(
      track: oldEntry.track.copyWith(isFavorited: liked),
      queuedAt: oldEntry.queuedAt,
    );
    _queueState = PlaybackQueueState(
      entries: List.unmodifiable(entries),
      currentIndex: _queueState.currentIndex,
    );
  }

  Future<void> next() async {
    _queueState = _queueState.moveNext();
    _currentTicket = null;
    _currentError = null;
    await _resolveCurrentAndPreResolveNext();
  }

  Future<void> previous() async {
    _queueState = _queueState.movePrevious();
    _currentTicket = null;
    _currentError = null;
    await _resolveCurrentAndPreResolveNext();
  }

  Future<void> selectTrack(ProviderTrackRef trackRef) async {
    final index =
        _queueState.entries.indexWhere((entry) => entry.track.ref == trackRef);
    if (index == -1) {
      _currentError = StateError('Track not found in current queue');
      return;
    }
    _queueState = PlaybackQueueState(
      entries: _queueState.entries,
      currentIndex: index,
    );
    _currentTicket = null;
    _currentError = null;
    await _resolveCurrentAndPreResolveNext();
  }

  Future<void> refreshCurrentTicketIfNeeded({bool force = false}) async {
    final currentEntry = _queueState.current;
    if (currentEntry == null) return;

    final ticket = _currentTicket;
    if (force ||
        ticket == null ||
        ticket.trackRef != currentEntry.track.ref ||
        ticket.quality != _quality ||
        ticket.isNearExpiry()) {
      try {
        _currentTicket = await _resolveTicketForTrack(currentEntry.track);
        _currentError = null;
      } catch (e) {
        // ignore: avoid_print
        print('PlaybackCoordinator: failed to refresh ticket for ${currentEntry.track.title}: $e');
        _currentTicket = null;
        _currentError = e;
      }
    }
  }

  Future<PlaybackTicket> getOrResolveCurrentTicket() async {
    final currentEntry = _queueState.current;
    if (currentEntry == null) {
      throw StateError('Queue is empty or index is invalid');
    }

    await refreshCurrentTicketIfNeeded();
    final ticket = _currentTicket;
    if (ticket == null) {
      final err = _currentError;
      if (err != null) {
        throw err;
      }
      throw StateError('Failed to resolve current ticket');
    }
    return ticket;
  }

  Future<void> _resolveCurrentAndPreResolveNext() async {
    final currentEntry = _queueState.current;
    if (currentEntry == null) {
      _currentTicket = null;
      _nextTicket = null;
      return;
    }

    // If nextTicket is already pre-resolved for this track, we can promote it!
    final pTicket = _nextTicket;
    if (pTicket != null &&
        pTicket.trackRef == currentEntry.track.ref &&
        !pTicket.isExpired) {
      _currentTicket = pTicket;
      _nextTicket = null;
    } else {
      try {
        _currentTicket = await _resolveTicketForTrack(currentEntry.track);
        _currentError = null;
      } catch (e) {
        // ignore: avoid_print
        print('PlaybackCoordinator: failed to resolve ticket for ${currentEntry.track.title}: $e');
        _currentTicket = null;
        _currentError = e;
      }
    }

    // Pre-resolve next track if available
    await preResolveNext();
  }

  Future<void> preResolveNext() async {
    final nextIndex = _queueState.currentIndex + 1;
    if (nextIndex >= 0 && nextIndex < _queueState.entries.length) {
      final nextTrack = _queueState.entries[nextIndex].track;
      try {
        _nextTicket = await _resolveTicketForTrack(nextTrack);
      } catch (_) {
        _nextTicket = null;
      }
    } else {
      _nextTicket = null;
    }
  }

  Future<PlaybackTicket> _resolveTicketForTrack(SourceTrack track) async {
    final providerId = track.ref.providerId;
    final entry = registry.entryOf(providerId);

    if (entry == null) {
      throw ProviderException(
        providerId: providerId,
        message: 'Provider ${providerId.value} is not registered.',
      );
    }

    if (!entry.isEnabled) {
      throw ProviderDisabledException(
        providerId: providerId,
        message: 'Provider ${providerId.value} is disabled.',
      );
    }

    final provider = entry.provider;
    if (!provider.descriptor.supports(ProviderCapability.resolvePlayback)) {
      throw CapabilityUnavailableException(
        providerId: providerId,
        capability: ProviderCapability.resolvePlayback,
        message: 'Provider ${providerId.value} does not support playback.',
      );
    }

    return await provider.createPlaybackTicket(
      track: track.ref,
      quality: _quality,
    );
  }
}
