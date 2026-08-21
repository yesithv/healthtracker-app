import 'dart:async';

import 'package:myvitals_healthtracker_app/core/diagnostics/debug_log.dart';

import 'package:flutter/foundation.dart';

import '../../features/discover/data/models/discover_feed.dart';
import '../../features/discover/data/repositories/discover_repository.dart';

/// App-lifetime holder for the Discover feed.
///
/// Warmed once at startup (registered `lazy: false` in `main.dart`) so the feed
/// is already in memory before the user ever taps the Discover tab — the screen
/// renders instantly instead of showing a spinner. Follows a
/// **stale-while-revalidate** policy: show the cached feed immediately, then
/// refresh the freshest source in the background and swap in the result.
class DiscoverProvider extends ChangeNotifier {
  DiscoverProvider({DiscoverRepository? repository})
    : _repository = repository ?? DiscoverRepository.instance;

  final DiscoverRepository _repository;

  DiscoverFeed _feed = DiscoverFeed.empty;
  DiscoverFeed get feed => _feed;

  /// The language the current [_feed] was loaded for.
  String? _loadedLang;

  bool _isLoading = false;
  bool _isRefreshing = false;

  /// True only on a genuine cold start with nothing cached yet — the one moment
  /// the UI shows skeleton placeholders.
  bool get isColdStart => _isLoading && _feed.isEmpty;
  bool get isRefreshing => _isRefreshing;
  bool get hasContent => !_feed.isEmpty;

  /// Ensures the feed for [lang] is loaded. Cheap to call on every screen build:
  /// it no-ops when the feed is already present, and never blocks the UI.
  Future<void> ensureLoaded(String lang) async {
    if (_loadedLang == lang && hasContent) {
      // Already have this language cached; quietly revalidate in the background.
      unawaited(_revalidate(lang));
      return;
    }
    if (_isLoading) return;

    // Instant path: adopt any in-memory feed synchronously before awaiting.
    final peek = _repository.peek(lang);
    if (peek != null && !peek.isEmpty) {
      _feed = peek;
      _loadedLang = lang;
      notifyListeners();
    }

    _isLoading = true;
    if (_feed.isEmpty) notifyListeners();
    try {
      final loaded = await _repository.load(lang);
      _feed = loaded;
      _loadedLang = lang;
    } catch (e) {
      debugLogError('Discover.load', e);
      // Keep whatever we had; the seed asset makes total failure unlikely.
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    unawaited(_revalidate(lang));
  }

  /// Force a refresh from the freshest source (pull-to-refresh).
  Future<void> refresh(String lang) => _revalidate(lang, force: true);

  Future<void> _revalidate(String lang, {bool force = false}) async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    if (force) notifyListeners();
    try {
      final fresh = await _repository.refresh(lang);
      _feed = fresh;
      _loadedLang = lang;
    } catch (e) {
      debugLogError('Discover.refresh', e);
      // Stale content stays on screen; nothing to do.
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }
}
