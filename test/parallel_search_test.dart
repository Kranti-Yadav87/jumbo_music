import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/models/song.dart';
import 'package:jumbo_music/services/music_api_service.dart';

Song testSong(
  String id,
  String title,
  String artist, {
  String? audioUrl,
  Duration duration = const Duration(seconds: 190),
  int viewCount = 0,
  int likeCount = 0,
  String description = '',
  List<String> tags = const [],
  String categoryId = '',
  String uploaderName = '',
}) {
  return Song(
    id: id,
    title: title,
    artist: artist,
    uploaderName: uploaderName,
    album: '',
    duration: duration,
    audioUrl: audioUrl ?? 'https://example.com/$id.mp3',
    coverUrl: '',
    viewCount: viewCount,
    likeCount: likeCount,
    description: description,
    tags: tags,
    categoryId: categoryId,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Shared search relevance ranking', () {
    test('Heer by Afusic ranks the matching title and artist first', () {
      final jioSongs = [
        testSong('js_heer_1', 'Heer', 'A.R. Rahman, Harshdeep Kaur'),
        testSong('js_heer_2', 'Heer Raanjhana', 'Arijit Singh'),
      ];

      final ytSongs = [
        testSong('yt_heer_afusic', 'Heer', 'Afusic & AliSoomroMusic'),
      ];

      final results = MusicApiService.rankSearchResultsForTesting(
        'Heer by Afusic',
        jioSongs,
        ytSongs,
      );

      expect(results, isNotEmpty);
      expect(results.first.id, 'yt_heer_afusic');
      expect(results.first.artist, contains('Afusic'));
    });

    test('Exact Jamendo title and artist can rank first in merged results', () {
      final jioSongs = [testSong('jio_wrong_heer', 'Heer', 'A.R. Rahman')];
      final jamendoSongs = [testSong('jamendo_heer_afusic', 'Heer', 'Afusic')];

      final results = MusicApiService.rankSearchResultsForTesting(
        'Heer by Afusic',
        jioSongs,
        const [],
        jamendoSongs: jamendoSongs,
      );

      expect(results, isNotEmpty);
      expect(results.first.id, 'jamendo_heer_afusic');
    });

    test('Jamendo duplicates are removed across providers', () {
      final results = MusicApiService.rankSearchResultsForTesting(
        'Heer by Afusic',
        [testSong('jio_heer', 'Heer', 'Afusic')],
        const [],
        jamendoSongs: [testSong('jamendo_heer', 'Heer', 'Afusic')],
      );

      expect(results, hasLength(1));
    });

    test('Artist-only query prioritizes matching artist', () {
      final songs = [
        testSong('wrong_artist', 'Heer', 'Arijit Singh'),
        testSong('afusic_artist', 'Heer', 'Afusic'),
        testSong('another_artist', 'Tum Hi Ho', 'Unknown Singer'),
      ];

      final results = MusicApiService.rankSearchResultsForTesting(
        'Afusic',
        songs,
        const [],
      );

      expect(results, isNotEmpty);
      expect(results.first.id, 'afusic_artist');
    });

    test('Title-only query ranks exact title first', () {
      final songs = [
        testSong('remix', 'Heer Acoustic Remix', 'Another Singer'),
        testSong('exact', 'Heer', 'Afusic'),
        testSong('extended', 'Heer Raanjhana', 'Arijit Singh'),
      ];

      final results = MusicApiService.rankSearchResultsForTesting(
        'Heer',
        songs,
        const [],
      );

      expect(results.first.id, 'exact');
    });

    test('Duplicate title and artist from providers are deduplicated', () {
      final jioSongs = [testSong('jio_heer', 'Heer', 'Afusic')];
      final ytSongs = [testSong('yt_heer', 'Heer', 'Afusic')];

      final results = MusicApiService.rankSearchResultsForTesting(
        'Heer by Afusic',
        jioSongs,
        ytSongs,
      );

      expect(results, hasLength(1));
    });

    test('Result limit is respected', () {
      final songs = [
        testSong('one', 'Heer', 'Afusic'),
        testSong('two', 'Heer Remix', 'Afusic'),
        testSong('three', 'Heer Acoustic', 'Afusic'),
      ];

      final results = MusicApiService.rankSearchResultsForTesting(
        'Heer Afusic',
        songs,
        const [],
        limit: 2,
      );

      expect(results, hasLength(2));
    });

    test('Exact title and artist beat an unrelated viral result', () {
      final songs = [
        testSong(
          'viral_unrelated',
          'Trending Party Song',
          'Popular Singer',
          viewCount: 50000000,
          likeCount: 2000000,
        ),
        testSong(
          'heer_afusic',
          'Heer',
          'Afusic',
          viewCount: 1200,
          likeCount: 80,
        ),
      ];

      final results = MusicApiService.rankSearchResultsForTesting(
        'Heer by Afusic',
        songs,
        const [],
      );

      expect(results.first.id, 'heer_afusic');
    });

    test('Original result ranks above explicit karaoke and cover versions', () {
      final songs = [
        testSong(
          'karaoke',
          'Heer Karaoke Version',
          'Music Track',
          viewCount: 500000,
        ),
        testSong(
          'cover',
          'Heer Cover',
          'Independent Singer',
          viewCount: 300000,
        ),
        testSong(
          'original',
          'Heer',
          'Afusic',
          description: 'Official audio',
          viewCount: 10000,
        ),
      ];

      final results = MusicApiService.rankSearchResultsForTesting(
        'Heer by Afusic',
        songs,
        const [],
      );

      expect(results.first.id, 'original');
    });

    test('Incidental description mentions do not penalize original tracks', () {
      final songs = [
        testSong(
          'cover_art_original',
          'Heer',
          'Afusic',
          description: 'Original audio. Cover art by the design team.',
        ),
        testSong(
          'not_cover_original',
          'Heer Original Audio',
          'Afusic',
          description: 'This is not a cover. Enjoy the original song.',
        ),
        testSong(
          'explicit_cover',
          'Heer Cover Version',
          'Another Singer',
          description: 'A cover version of the song.',
        ),
      ];

      final results = MusicApiService.rankSearchResultsForTesting(
        'Heer by Afusic',
        songs,
        const [],
      );

      expect(results.first.id, 'cover_art_original');
      expect(results[1].id, 'not_cover_original');
      expect(results.last.id, 'explicit_cover');
    });

    test('Explicit cover wording in description is penalized', () {
      final songs = [
        testSong(
          'description_cover',
          'Heer',
          'Another Singer',
          description: 'I recorded a cover for this song.',
        ),
        testSong(
          'original_recording',
          'Heer',
          'Afusic',
          description: 'Original studio recording.',
        ),
      ];

      final results = MusicApiService.rankSearchResultsForTesting(
        'Heer',
        songs,
        const [],
      );

      expect(results.first.id, 'original_recording');
    });

    test('Low-view independent artist is not penalized', () {
      final songs = [
        testSong('popular_wrong', 'Heer', 'Another Singer', viewCount: 9000000),
        testSong(
          'independent_exact',
          'Heer',
          'Afusic',
          viewCount: 250,
          likeCount: 12,
        ),
      ];

      final results = MusicApiService.rankSearchResultsForTesting(
        'Heer by Afusic',
        songs,
        const [],
      );

      expect(results.first.id, 'independent_exact');
    });

    test('Popularity breaks ties between equally relevant results', () {
      final songs = [
        testSong(
          'less_popular',
          'Heer',
          'Afusic',
          viewCount: 1000,
          likeCount: 20,
        ),
        testSong(
          'more_popular',
          'Heer',
          'Afusic',
          viewCount: 1000000,
          likeCount: 50000,
        ),
      ];

      final results = MusicApiService.rankSearchResultsForTesting(
        'Heer by Afusic',
        songs,
        const [],
      );

      expect(results.first.id, 'more_popular');
    });

    test('Short original tracks are retained', () {
      final songs = [
        testSong(
          'short_original',
          'Heer',
          'Afusic',
          duration: const Duration(seconds: 45),
        ),
      ];

      final results = MusicApiService.rankSearchResultsForTesting(
        'Heer by Afusic',
        songs,
        const [],
      );

      expect(results, hasLength(1));
      expect(results.first.id, 'short_original');
    });

    test('YouTube low-quality versions and short clips are filtered', () {
      final songs = [
        testSong(
          'yt_original_heer',
          'Heer',
          'Afusic',
          duration: const Duration(seconds: 190),
          uploaderName: 'Afusic',
        ),
        testSong('yt_cover_heer', 'Heer by Afusic Cover', 'Unknown Artist'),
        testSong(
          'yt_lyrics_video',
          'Heer by Afusic',
          'Unknown Artist',
          description: 'Official lyrics video',
        ),
        testSong(
          'yt_slowed_reverb',
          'Heer Afusic Slowed and Reverb',
          'Unknown Artist',
        ),
        testSong(
          'yt_short_clip',
          'Heer by Afusic',
          'Unknown Artist',
          duration: const Duration(seconds: 35),
          tags: const ['#shorts'],
        ),
        testSong('yt_karaoke', 'Heer Karaoke', 'Unknown Artist'),
      ];

      final results = MusicApiService.rankSearchResultsForTesting(
        'Heer by Afusic',
        const [],
        songs,
      );

      expect(results.map((song) => song.id), ['yt_original_heer']);
    });

    test('YouTube original with cover art description is retained', () {
      final songs = [
        testSong(
          'yt_original_cover_art',
          'Heer',
          'Afusic',
          description: 'Original audio. Cover art by the design team.',
          duration: const Duration(seconds: 190),
        ),
      ];

      final results = MusicApiService.rankSearchResultsForTesting(
        'Heer by Afusic',
        const [],
        songs,
      );

      expect(results, hasLength(1));
      expect(results.first.id, 'yt_original_cover_art');
    });

    test('Uploader match helps identify an unknown-artist YouTube result', () {
      final songs = [
        testSong(
          'yt_wrong_uploader',
          'Heer',
          'Unknown Artist',
          uploaderName: 'Another Channel',
        ),
        testSong(
          'yt_afusic_uploader',
          'Heer',
          'Unknown Artist',
          uploaderName: 'Afusic',
        ),
      ];

      final results = MusicApiService.rankSearchResultsForTesting(
        'Heer by Afusic',
        const [],
        songs,
      );

      expect(results.first.id, 'yt_afusic_uploader');
    });

    test(
      'Uploader matching does not accept partial artist-name substrings',
      () {
        final songs = [
          testSong('yt_no_match', 'Heer', 'Unknown Artist'),
          testSong(
            'yt_substring_match',
            'Heer',
            'Unknown Artist',
            uploaderName: 'Artist Hub',
          ),
        ];

        final results = MusicApiService.rankSearchResultsForTesting(
          'Heer by Art',
          const [],
          songs,
        );

        expect(results.first.id, 'yt_no_match');
      },
    );

    test('Real artist match ranks above uploader-only match', () {
      final songs = [
        testSong(
          'uploader_only',
          'Heer',
          'Unknown Artist',
          uploaderName: 'Afusic',
        ),
        testSong('real_artist', 'Heer', 'Afusic'),
      ];

      final results = MusicApiService.rankSearchResultsForTesting(
        'Heer by Afusic',
        const [],
        songs,
      );

      expect(results.first.id, 'real_artist');
    });

    test('Unknown artist uploader deduplicates against real artist result', () {
      final jioSongs = [testSong('jio_heer', 'Heer', 'Afusic')];
      final ytSongs = [
        testSong('yt_heer', 'Heer', 'Unknown Artist', uploaderName: 'Afusic'),
      ];

      final results = MusicApiService.rankSearchResultsForTesting(
        'Heer by Afusic',
        jioSongs,
        ytSongs,
      );

      expect(results, hasLength(1));
    });

    test(
      'Unknown-artist uploader matching one collaboration artist deduplicates',
      () {
        final jioSongs = [
          testSong('jio_heer_collab', 'Heer', 'Afusic & AliSoomroMusic'),
        ];
        final ytSongs = [
          testSong(
            'yt_heer_afusic',
            'Heer',
            'Unknown Artist',
            uploaderName: 'Afusic',
          ),
        ];

        final results = MusicApiService.rankSearchResultsForTesting(
          'Heer by Afusic',
          jioSongs,
          ytSongs,
        );

        expect(results, hasLength(1));
        expect(results.first.id, 'jio_heer_collab');
      },
    );

    test('Different uploaders remain separate for unknown artists', () {
      final songs = [
        testSong('yt_afusic', 'Heer', 'Unknown Artist', uploaderName: 'Afusic'),
        testSong(
          'yt_other',
          'Heer',
          'Unknown Artist',
          uploaderName: 'Another Channel',
        ),
      ];

      final results = MusicApiService.rankSearchResultsForTesting(
        'Heer',
        const [],
        songs,
      );

      expect(results, hasLength(2));
    });

    test(
      'Different collaboration artist combinations are not deduplicated',
      () {
        final songs = [
          testSong('collab_ab', 'Heer', 'Artist A & Artist B'),
          testSong('collab_ac', 'Heer', 'Artist A & Artist C'),
        ];

        final results = MusicApiService.rankSearchResultsForTesting(
          'Heer',
          const [],
          songs,
        );

        expect(results, hasLength(2));
      },
    );

    test(
      'Unknown artists without uploader metadata are not title-deduplicated',
      () {
        final songs = [
          testSong('yt_one', 'Heer', 'Unknown Artist'),
          testSong('yt_two', 'Heer', 'Unknown Artist'),
        ];

        final results = MusicApiService.rankSearchResultsForTesting(
          'Heer',
          const [],
          songs,
        );

        expect(results, hasLength(2));
      },
    );

    test('Heer Afusic query matches an unknown-artist uploader', () {
      final jioSongs = [testSong('jio_generic_heer', 'Heer', 'A.R. Rahman')];
      final ytSongs = [
        testSong(
          'yt_wrong_heer',
          'Heer',
          'Unknown Artist',
          uploaderName: 'Another Channel',
        ),
        testSong(
          'yt_afusic_heer',
          'Heer',
          'Unknown Artist',
          uploaderName: 'Afusic Official',
        ),
      ];

      final results = MusicApiService.rankSearchResultsForTesting(
        'Heer Afusic',
        jioSongs,
        ytSongs,
      );

      expect(results.first.id, 'yt_afusic_heer');
    });

    test('Real artist match beats uploader-only match without by', () {
      final songs = [
        testSong(
          'uploader_only_no_by',
          'Heer',
          'Unknown Artist',
          uploaderName: 'Afusic',
        ),
        testSong('real_artist_no_by', 'Heer', 'Afusic'),
      ];

      final results = MusicApiService.rankSearchResultsForTesting(
        'Heer Afusic',
        const [],
        songs,
      );

      expect(results.first.id, 'real_artist_no_by');
    });

    test('Non-positive limit returns no results', () {
      final songs = [testSong('one', 'Heer', 'Afusic')];

      final results = MusicApiService.rankSearchResultsForTesting(
        'Heer',
        songs,
        const [],
        limit: 0,
      );

      expect(results, isEmpty);
    });
  });

  test('YouTube genuine short complete songs are retained', () {
    final songs = [
      testSong(
        'yt_genuine_short_song',
        'Tiny Song',
        'Artist',
        duration: const Duration(seconds: 35),
        uploaderName: 'Artist',
        description: 'Official audio - complete song',
      ),
    ];

    final results = MusicApiService.rankSearchResultsForTesting(
      'Tiny Song by Artist',
      const [],
      songs,
    );

    expect(results.map((song) => song.id), ['yt_genuine_short_song']);
  });
}
