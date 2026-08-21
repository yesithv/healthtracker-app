import 'dart:async';
import 'package:myvitals_healthtracker_app/core/diagnostics/debug_log.dart';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/api_config.dart';
import '../models/discover_feed.dart';

/// Local-first data source for the Discover feed.
///
/// Three layers, fastest first, so the screen never blocks on a spinner once the
/// app has been opened at least once:
///   1. **in-memory** — parsed feed kept for the app session (instant).
///   2. **persisted** — last known-good JSON in `SharedPreferences`, survives
///      restarts and (later) holds content pulled from the backoffice API.
///   3. **bundled asset** — `assets/data/discover_<lang>.json` seed that ships
///      with the app, so a brand-new install works fully offline.
///
/// [refresh] re-reads the freshest source and updates the two caches. Today that
/// source is the bundled seed; wiring it to the backoffice content API later is
/// a one-method change ([_readFreshSource]) — nothing else moves.
class DiscoverRepository {
  DiscoverRepository._();
  static final DiscoverRepository instance = DiscoverRepository._();

  static const String _fallbackLang = 'en';
  static String _prefsKey(String lang) => 'discover_feed_cache_$lang';

  final Map<String, DiscoverFeed> _memory = {};

  /// Synchronous peek at the in-memory cache — used by the provider to render
  /// instantly on tab re-entry.
  DiscoverFeed? peek(String lang) => _memory[lang];

  /// Returns the fastest available feed: memory → persisted → bundled asset.
  Future<DiscoverFeed> load(String lang) async {
    final memory = _memory[lang];
    if (memory != null) return memory;

    final persisted = await _readPersisted(lang);
    if (persisted != null && !persisted.isEmpty) {
      _memory[lang] = persisted;
      return persisted;
    }

    // Cold start with nothing cached: use the bundled seed immediately so the UI
    // never waits on the network. The live API fetch happens in [refresh], which
    // the provider calls in the background right after this.
    final raw = await _readAsset(lang);
    final feed = DiscoverFeed.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    _memory[lang] = feed;
    unawaited(_persist(lang, raw));
    return feed;
  }

  /// Re-reads the freshest source, then updates memory + persisted caches.
  Future<DiscoverFeed> refresh(String lang) async {
    final raw = await _readFreshSource(lang);
    final feed = DiscoverFeed.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    _memory[lang] = feed;
    unawaited(_persist(lang, raw));
    return feed;
  }

  // --- source layers -------------------------------------------------------

  /// The authoritative content source: the live feed served by the
  /// HealthTracker-Api (`GET /api/v1/discover/feed?lang=`), which reads the content
  /// the backoffice authored. Falls back to the bundled seed asset whenever the
  /// network is unavailable or returns nothing usable, so the app always works
  /// offline and on a fresh install.
  Future<String> _readFreshSource(String lang) async {
    final fromApi = await _fetchFromApi(lang);
    if (fromApi != null) return fromApi;
    return _readAsset(lang);
  }

  /// Returns the raw feed JSON from the API, or `null` if it is unreachable,
  /// errors, times out, or comes back empty (in which case we prefer the seed).
  Future<String?> _fetchFromApi(String lang) async {
    if (ApiConfig.baseUrl.isEmpty) return null;
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/discover/feed?lang=$lang',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 4));
      if (resp.statusCode < 200 ||
          resp.statusCode >= 300 ||
          resp.body.isEmpty) {
        return null;
      }
      // Only trust a payload that parses and actually has content.
      final decoded = jsonDecode(resp.body);
      if (decoded is Map<String, dynamic> &&
          !DiscoverFeed.fromJson(decoded).isEmpty) {
        return resp.body;
      }
    } catch (e) {
      debugLogError('Discover.fetchRemote', e);
      // Network/parse failure → fall back to the bundled seed.
    }
    return null;
  }

  Future<String> _readAsset(String lang) async {
    try {
      return await rootBundle.loadString('assets/data/discover_$lang.json');
    } catch (e) {
      debugLogError('Discover.readAsset', e);
      return rootBundle.loadString('assets/data/discover_$_fallbackLang.json');
    }
  }

  Future<DiscoverFeed?> _readPersisted(String lang) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey(lang));
      if (raw == null || raw.isEmpty) return null;
      return DiscoverFeed.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugLogError('Discover.readPersisted', e);
      return null;
    }
  }

  Future<void> _persist(String lang, String raw) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey(lang), raw);
    } catch (e) {
      debugLogError('Discover.persist', e);
      // Persisting is a best-effort optimisation; ignore failures.
    }
  }
}
