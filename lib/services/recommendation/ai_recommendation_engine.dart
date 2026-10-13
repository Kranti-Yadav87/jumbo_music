import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../models/song.dart';
import '../database_service.dart';
import '../music_api_service.dart';

enum SongTempoCategory { slow, midTempo, upbeat }

enum SongMoodCategory {
  energetic,
  romantic,
  calmSukoon,
  nostalgicRetro,
  devotionalPositive,
}

/// Core AI Recommendation Engine for Jumbo Music.
/// Selects and auto-plays the best next songs based on:
/// 1. Collaborative Filtering (co-listening transitions & user clusters)
/// 2. Content-Based Filtering (genre, tempo, mood, era, artist styles)
/// 3. Contextual and Behavioral Signals (skips, favorites, search history, time-of-day)
class AiRecommendationEngine {
  static final AiRecommendationEngine instance =
      AiRecommendationEngine._internal();
  factory AiRecommendationEngine() => instance;
  AiRecommendationEngine._internal();

  /// Skip count map for behavioral penalty: songId -> skip count
  final Map<String, int> _skipCounts = {};

  /// Transition count map for Collaborative Filtering: songIdA -> (songIdB -> count)
  final Map<String, Map<String, int>> _transitionGraph = {};

  /// Custom time provider for unit testing
  DateTime Function() nowProvider = DateTime.now;

  @visibleForTesting
  void resetForTesting() {
    _skipCounts.clear();
    _transitionGraph.clear();
    nowProvider = DateTime.now;
  }

  // ==========================================
  // Pillar 1: Collaborative Filtering
  // ==========================================

  /// Records that track B was played right after track A (co-listening transition)
  void recordTransition(String trackAId, String trackBId) {
    if (trackAId.isEmpty || trackBId.isEmpty || trackAId == trackBId) return;
    final transitions = _transitionGraph.putIfAbsent(trackAId, () => {});
    transitions[trackBId] = (transitions[trackBId] ?? 0) + 1;
  }

  /// Calculates collaborative transition score from seed track A to candidate track B
  double calculateCollaborativeScore(Song seedSong, Song candidate) {
    double score = 0.1; // baseline

    // 1. Check direct transition graph
    final transitionsFromSeed = _transitionGraph[seedSong.id];
    if (transitionsFromSeed != null &&
        transitionsFromSeed.containsKey(candidate.id)) {
      final count = transitionsFromSeed[candidate.id]!;
      score += min(count * 0.25, 0.50);
    }

    // 2. Playlist Co-Occurrence (Collaborative cluster signal)
    final playlists = DatabaseService.instance.playlists;
    for (final playlist in playlists) {
      final hasSeed = playlist.songs.any((s) => s.id == seedSong.id);
      final hasCandidate = playlist.songs.any((s) => s.id == candidate.id);
      if (hasSeed && hasCandidate) {
        score += 0.35;
        break;
      }
    }

    // 3. Listening History Proximity (Shared session affinity)
    final history = DatabaseService.instance.historySongs;
    for (int i = 0; i < history.length - 1; i++) {
      if ((history[i].id == seedSong.id && history[i + 1].id == candidate.id) ||
          (history[i].id == candidate.id && history[i + 1].id == seedSong.id)) {
        score += 0.25;
        break;
      }
    }

    return score.clamp(0.0, 1.0);
  }

  // ==========================================
  // Pillar 2: Content-Based Filtering
  // ==========================================

  SongTempoCategory estimateTempo(Song song) {
    final title = song.title.toLowerCase();
    final artist = song.artist.toLowerCase();

    if (title.contains('remix') ||
        title.contains('party') ||
        title.contains('dance') ||
        title.contains('dj') ||
        title.contains('dynamite') ||
        title.contains('butter') ||
        title.contains('dhol') ||
        title.contains('bhangra') ||
        title.contains('club')) {
      return SongTempoCategory.upbeat;
    }

    if (title.contains('lofi') ||
        title.contains('lo-fi') ||
        title.contains('acoustic') ||
        title.contains('sukoon') ||
        title.contains('unplugged') ||
        title.contains('slowed') ||
        title.contains('reverb') ||
        title.contains('ghazal') ||
        title.contains('sad') ||
        artist.contains('jagjit singh')) {
      return SongTempoCategory.slow;
    }

    return SongTempoCategory.midTempo;
  }

  SongMoodCategory classifyMood(Song song) {
    final title = song.title.toLowerCase();
    final artist = song.artist.toLowerCase();

    if (title.contains('bhajan') ||
        title.contains('aarti') ||
        title.contains('hanuman') ||
        title.contains('shiva') ||
        title.contains('krishna') ||
        title.contains('prayer')) {
      return SongMoodCategory.devotionalPositive;
    }

    if (MusicApiService.isVintageGoldenEra(song) ||
        MusicApiService.is80sEra(song)) {
      return SongMoodCategory.nostalgicRetro;
    }

    if (title.contains('party') ||
        title.contains('dance') ||
        title.contains('dynamite') ||
        title.contains('remix') ||
        title.contains('dj') ||
        artist.contains('badshah') ||
        artist.contains('honey singh')) {
      return SongMoodCategory.energetic;
    }

    if (title.contains('lofi') ||
        title.contains('sukoon') ||
        title.contains('acoustic') ||
        title.contains('peace') ||
        MusicApiService.isIndieOrSukoonSong(song) ||
        artist.contains('prateek kuhad') ||
        artist.contains('anuv jain')) {
      return SongMoodCategory.calmSukoon;
    }

    return SongMoodCategory.romantic;
  }

  /// Calculates content similarity between seed song and candidate
  double calculateContentScore(Song seedSong, Song candidate) {
    double score = 0.0;

    // A. Language match (30%)
    final seedLang = MusicApiService.detectSongLanguage(seedSong);
    final candLang = MusicApiService.detectSongLanguage(candidate);
    if (seedLang == candLang) {
      score += 0.30;
    }

    // B. Artist affinity (25%)
    final seedArtist = seedSong.artist.split(',').first.trim().toLowerCase();
    final candArtist = candidate.artist.split(',').first.trim().toLowerCase();
    if (seedArtist == candArtist) {
      score += 0.25;
    } else if (seedSong.artist.toLowerCase().contains(candArtist) ||
        candidate.artist.toLowerCase().contains(seedArtist)) {
      score += 0.15;
    }

    // C. Tempo consistency (20%)
    final seedTempo = estimateTempo(seedSong);
    final candTempo = estimateTempo(candidate);
    if (seedTempo == candTempo) {
      score += 0.20;
    } else if ((seedTempo == SongTempoCategory.midTempo &&
            candTempo == SongTempoCategory.slow) ||
        (seedTempo == SongTempoCategory.midTempo &&
            candTempo == SongTempoCategory.upbeat)) {
      score += 0.10; // smooth adjacent transition
    }

    // D. Mood consistency (25%)
    final seedMood = classifyMood(seedSong);
    final candMood = classifyMood(candidate);
    if (seedMood == candMood) {
      score += 0.25;
    } else if ((seedMood == SongMoodCategory.romantic &&
            candMood == SongMoodCategory.calmSukoon) ||
        (seedMood == SongMoodCategory.energetic &&
            candMood == SongMoodCategory.romantic)) {
      score += 0.12;
    }

    return score.clamp(0.0, 1.0);
  }

  // ==========================================
  // Pillar 3: Contextual and Behavioral Signals
  // ==========================================

  void recordSkip(String songId) {
    if (songId.isEmpty) return;
    _skipCounts[songId] = (_skipCounts[songId] ?? 0) + 1;
  }

  /// Calculates real-time behavioral adjustments & time-of-day contextual modulation
  double calculateContextualAndBehavioralScore(Song candidate) {
    double modifier = 0.0;

    // 1. Skip penalty: penalize songs the user skips repeatedly
    final skips = _skipCounts[candidate.id] ?? 0;
    if (skips >= 3) {
      return -1.0; // completely exclude heavily skipped tracks
    } else if (skips == 2) {
      modifier -= 0.60;
    } else if (skips == 1) {
      modifier -= 0.25;
    }

    // 2. Behavioral positive signals
    final db = DatabaseService.instance;

    // A. Favorited by user (+30%)
    if (db.favoriteSongs.any((s) => s.id == candidate.id)) {
      modifier += 0.30;
    }

    // B. Added to custom playlist (+25%)
    final inPlaylists = db.playlists.any(
      (p) => p.songs.any((s) => s.id == candidate.id),
    );
    if (inPlaylists) {
      modifier += 0.25;
    }

    // C. History repetition (+20%)
    final historyCount = db.historySongs
        .where((s) => s.id == candidate.id)
        .length;
    if (historyCount >= 2) {
      modifier += 0.20;
    }

    // D. Search history query relevance (+40%)
    final searchTerms = db.searchHistory;
    final candTitleLower = candidate.title.toLowerCase();
    final candArtistLower = candidate.artist.toLowerCase();
    for (final term in searchTerms) {
      final t = term.trim().toLowerCase();
      if (t.isNotEmpty &&
          (candTitleLower.contains(t) || candArtistLower.contains(t))) {
        modifier += 0.40;
        break;
      }
    }

    // 3. Contextual Time-of-Day Modulation
    final currentHour = nowProvider().hour;
    final mood = classifyMood(candidate);
    final tempo = estimateTempo(candidate);

    if (currentHour >= 5 && currentHour < 11) {
      // Morning (5 AM - 11 AM): fresh, uplifting, devotional, energetic
      if (mood == SongMoodCategory.devotionalPositive ||
          mood == SongMoodCategory.energetic) {
        modifier += 0.20;
      }
    } else if (currentHour >= 11 && currentHour < 17) {
      // Daytime (11 AM - 5 PM): upbeat, trending, high energy
      if (tempo == SongTempoCategory.upbeat ||
          mood == SongMoodCategory.energetic) {
        modifier += 0.25;
      }
    } else if (currentHour >= 17 && currentHour < 22) {
      // Evening (5 PM - 10 PM): melodious, romantic, acoustic
      if (mood == SongMoodCategory.romantic ||
          mood == SongMoodCategory.nostalgicRetro) {
        modifier += 0.25;
      }
    } else {
      // Late Night (10 PM - 5 AM): calm, sukoon, lofi, ambient, slow tempo
      if (mood == SongMoodCategory.calmSukoon ||
          tempo == SongTempoCategory.slow) {
        modifier += 0.35;
      } else if (tempo == SongTempoCategory.upbeat) {
        modifier -= 0.20; // de-emphasize party beats during late night
      }
    }

    return modifier;
  }

  // ==========================================
  // Ensemble Ranking & Queue Generation
  // ==========================================

  /// Computes composite recommendation score for candidate following seedSong
  double scoreCandidate(Song seedSong, Song candidate) {
    if (candidate.audioUrl.trim().isEmpty) return -100.0;
    if (candidate.id == seedSong.id) return -100.0;

    final collabScore = calculateCollaborativeScore(seedSong, candidate);
    final contentScore = calculateContentScore(seedSong, candidate);
    final contextBehavior = calculateContextualAndBehavioralScore(candidate);

    if (contextBehavior <= -0.99) {
      return -100.0; // suppressed due to repeated skips
    }

    // Weighted fusion: 35% Collaborative + 35% Content + 30% Contextual/Behavioral
    return (0.35 * collabScore) + (0.35 * contentScore) + contextBehavior;
  }

  /// Selects the single best next song from a candidate list
  Song? selectBestNextSong({
    required Song currentSong,
    required List<Song> candidates,
  }) {
    if (candidates.isEmpty) return null;

    Song? bestSong;
    double highestScore = -999.0;

    for (final candidate in candidates) {
      if (candidate.id == currentSong.id) continue;
      final s = scoreCandidate(currentSong, candidate);
      if (s > highestScore) {
        highestScore = s;
        bestSong = candidate;
      }
    }

    return bestSong;
  }

  /// Builds a high-accuracy, personalized queue starting from seedSong.
  /// Combines:
  /// - User's search history inspirations
  /// - User's playlists and favorites
  /// - Live recommendations matching seedSong
  /// - User's listening feed
  Future<List<Song>> buildSmartQueue({
    required Song seedSong,
    List<Song> existingQueue = const [],
    int targetSize = 50,
  }) async {
    final List<Song> pool = [];
    final Set<String> seenIds = {seedSong.id};

    for (final eq in existingQueue) {
      if (eq.id != seedSong.id &&
          eq.audioUrl.trim().isNotEmpty &&
          seenIds.add(eq.id)) {
        pool.add(eq);
      }
    }

    final db = DatabaseService.instance;

    // 1. Gather candidates from user's favorites & playlists matching genre/mood
    for (final fav in db.favoriteSongs) {
      if (fav.audioUrl.trim().isNotEmpty && seenIds.add(fav.id)) {
        pool.add(fav);
      }
    }
    for (final pl in db.playlists) {
      for (final s in pl.songs) {
        if (s.audioUrl.trim().isNotEmpty && seenIds.add(s.id)) {
          pool.add(s);
        }
      }
    }

    // 2. Gather candidates from user's recent search queries
    final recentSearches = db.searchHistory.take(3);
    for (final query in recentSearches) {
      try {
        final searchMatches = await MusicApiService.searchLiveSongs(
          query,
          limit: 10,
        );
        for (final sm in searchMatches) {
          if (sm.audioUrl.trim().isNotEmpty && seenIds.add(sm.id)) {
            pool.add(sm);
          }
        }
      } catch (_) {}
    }

    // 3. Live smart recommendations for seedSong
    try {
      final recs = await MusicApiService.fetchSmartRecommendations(
        seedSong,
        limit: 45,
      );
      for (final r in recs) {
        if (r.audioUrl.trim().isNotEmpty && seenIds.add(r.id)) {
          pool.add(r);
        }
      }
    } catch (_) {}

    // 4. Score all candidates using the 3 Pillars
    final List<MapEntry<Song, double>> scored = [];
    for (final candidate in pool) {
      final score = scoreCandidate(seedSong, candidate);
      if (score > -50.0) {
        scored.add(MapEntry(candidate, score));
      }
    }

    // Sort descending by score
    scored.sort((a, b) => b.value.compareTo(a.value));

    // Deduplicate songs by title/artist key
    final List<Song> rankedSongs = [seedSong];
    final Set<String> seenKeys = {
      SongParserUtils.songDeduplicationKey(seedSong),
    };

    for (final entry in scored) {
      final key = SongParserUtils.songDeduplicationKey(entry.key);
      if (seenKeys.add(key)) {
        rankedSongs.add(entry.key);
        if (rankedSongs.length >= targetSize) break;
      }
    }

    return rankedSongs;
  }
}
