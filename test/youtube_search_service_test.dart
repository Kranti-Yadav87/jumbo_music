import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/models/song.dart';
import 'package:jumbo_music/services/api/youtube_search_service.dart';

Song _testSong(String id, String title, String artist) {
  return Song(
    id: id,
    title: title,
    artist: artist,
    duration: const Duration(minutes: 3),
    audioUrl: '',
    coverUrl: '',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('YouTubeSearchService Unit Tests', () {
    test('parseSearchResults parses InnerTube JSON response correctly', () {
      final sampleJson = {
        'contents': {
          'tabbedSearchResultsRenderer': {
            'tabs': [
              {
                'tabRenderer': {
                  'content': {
                    'sectionListRenderer': {
                      'contents': [
                        {
                          'musicShelfRenderer': {
                            'contents': [
                              {
                                'musicResponsiveListItemRenderer': {
                                  'playlistItemData': {
                                    'videoId': 'gD4EtH2Plik',
                                  },
                                  'flexColumns': [
                                    {
                                      'musicResponsiveListItemFlexColumnRenderer':
                                          {
                                            'text': {
                                              'runs': [
                                                {'text': '295'},
                                              ],
                                            },
                                          },
                                    },
                                    {
                                      'musicResponsiveListItemFlexColumnRenderer':
                                          {
                                            'text': {
                                              'runs': [
                                                {'text': 'Sidhu Moose Wala'},
                                                {'text': ' • '},
                                                {'text': 'Moosetape'},
                                                {'text': ' • '},
                                                {'text': '4:30'},
                                              ],
                                            },
                                          },
                                    },
                                  ],
                                  'thumbnail': {
                                    'musicThumbnailRenderer': {
                                      'thumbnail': {
                                        'thumbnails': [
                                          {
                                            'url':
                                                'https://yt3.googleusercontent.com/test=w120-h120-l90-rj',
                                            'width': 120,
                                            'height': 120,
                                          },
                                        ],
                                      },
                                    },
                                  },
                                },
                              },
                            ],
                          },
                        },
                      ],
                    },
                  },
                },
              },
            ],
          },
        },
      };

      final songs = YouTubeSearchService.parseSearchResults(sampleJson);
      expect(songs.length, equals(1));

      final song = songs.first;
      expect(song.id, equals('yt_gD4EtH2Plik'));
      expect(song.title, equals('295'));
      expect(song.artist, equals('Sidhu Moose Wala'));
      expect(song.album, equals('Moosetape'));
      expect(song.duration, equals(const Duration(minutes: 4, seconds: 30)));
      expect(song.coverUrl, contains('=w540-h540-l90-rj'));
      expect(song.language, equals('Punjabi'));
    });

    test('parseSearchResults handles empty/malformed responses safely', () {
      expect(YouTubeSearchService.parseSearchResults({}), isEmpty);
      expect(
        YouTubeSearchService.parseSearchResults({'contents': {}}),
        isEmpty,
      );
    });

    test('parseDataApiSearchResults parses YouTube Data API response', () {
      final songs = YouTubeSearchService.parseDataApiSearchResults({
        'items': [
          {
            'videoId': 'gD4EtH2Plik',
            'title': '295',
            'channelTitle': 'Sidhu Moose Wala',
            'publishedAt': '2022-05-15T10:00:00Z',
            'thumbnail': 'https://example.com/thumbnail.jpg',
            'durationSeconds': 270,
          },
        ],
      });

      expect(songs, hasLength(1));
      expect(songs.first.id, 'yt_gD4EtH2Plik');
      expect(songs.first.title, '295');
      expect(songs.first.artist, 'Sidhu Moose Wala');
      expect(songs.first.duration, const Duration(seconds: 270));
      expect(songs.first.coverUrl, 'https://example.com/thumbnail.jpg');
      expect(songs.first.releaseYear, '2022');
    });

    test('parseDataApiSearchResults ignores invalid and duplicate videos', () {
      final songs = YouTubeSearchService.parseDataApiSearchResults({
        'items': [
          {
            'videoId': 'invalid-id',
            'title': 'Invalid video',
            'channelTitle': 'Channel',
          },
          {
            'videoId': 'gD4EtH2Plik',
            'title': 'Valid video',
            'channelTitle': 'Channel',
            'durationSeconds': 120,
          },
          {
            'videoId': 'gD4EtH2Plik',
            'title': 'Duplicate video',
            'channelTitle': 'Channel',
            'durationSeconds': 180,
          },
        ],
      });

      expect(songs, hasLength(1));
      expect(songs.first.title, 'Valid video');
    });

    test('parseDataApiSearchResults handles missing fields and limits', () {
      final songs = YouTubeSearchService.parseDataApiSearchResults({
        'items': [
          {'videoId': 'abcdefghijk', 'title': 'Video without metadata'},
          {
            'videoId': 'lmnopqrstuv',
            'title': 'Second video',
            'channelTitle': 'Channel',
            'durationSeconds': -10,
          },
        ],
      }, limit: 1);

      expect(songs, hasLength(1));
      expect(songs.first.artist, 'YouTube');
      expect(songs.first.duration, Duration.zero);
      expect(YouTubeSearchService.parseDataApiSearchResults({}), isEmpty);
    });

    test('normalizeQuery strips conversational connectors accurately', () {
      expect(
        YouTubeSearchService.normalizeQuery('Heer by afusic'),
        equals('Heer afusic'),
      );
      expect(
        YouTubeSearchService.normalizeQuery('afusic song'),
        equals('afusic'),
      );
      expect(
        YouTubeSearchService.normalizeQuery('dil by afusic official video'),
        equals('dil afusic'),
      );
      expect(
        YouTubeSearchService.normalizeQuery('shape of you by ed sheeran'),
        equals('shape of you ed sheeran'),
      );
      expect(
        YouTubeSearchService.normalizeQuery('Stand By Me'),
        equals('Stand Me'),
      );
    });

    test('parseSearchResults parses musicCardShelfRenderer top hero card', () {
      final heroCardJson = {
        'contents': {
          'tabbedSearchResultsRenderer': {
            'tabs': [
              {
                'tabRenderer': {
                  'content': {
                    'sectionListRenderer': {
                      'contents': [
                        {
                          'musicCardShelfRenderer': {
                            'title': {
                              'runs': [
                                {'text': 'Heer'},
                              ],
                            },
                            'subtitle': {
                              'runs': [
                                {'text': 'Song'},
                                {'text': ' • '},
                                {'text': 'Afusic & AliSoomroMusic'},
                                {'text': ' • '},
                                {'text': '3:17'},
                              ],
                            },
                            'onTap': {
                              'watchEndpoint': {'videoId': 'mOB1S1qXcPQ'},
                            },
                            'thumbnail': {
                              'musicThumbnailRenderer': {
                                'thumbnail': {
                                  'thumbnails': [
                                    {
                                      'url':
                                          'https://lh3.googleusercontent.com/cover=w120-h120',
                                    },
                                  ],
                                },
                              },
                            },
                          },
                        },
                      ],
                    },
                  },
                },
              },
            ],
          },
        },
      };

      final songs = YouTubeSearchService.parseSearchResults(heroCardJson);
      expect(songs.length, equals(1));
      expect(songs.first.id, equals('yt_mOB1S1qXcPQ'));
      expect(songs.first.title, equals('Heer'));
      expect(songs.first.artist, equals('Afusic & AliSoomroMusic'));
      expect(
        songs.first.duration,
        equals(const Duration(minutes: 3, seconds: 17)),
      );
    });

    test('rankSearchResults prioritizes matching title and artist', () {
      final songs = [
        _testSong('1', 'Random Track', 'Unknown Artist'),
        _testSong('2', 'Heer', 'Afusic'),
        _testSong('3', 'Heer Acoustic', 'Another Singer'),
      ];

      final ranked = YouTubeSearchService.rankSearchResults(
        songs,
        'Heer by Afusic',
      );

      expect(ranked.first.id, '2');
    });

    test('rankSearchResults preserves original order for equal scores', () {
      final songs = [
        _testSong('first', 'Heer Remix', 'Singer One'),
        _testSong('second', 'Heer Version', 'Singer Two'),
      ];

      final ranked = YouTubeSearchService.rankSearchResults(songs, 'Heer');

      expect(ranked.map((song) => song.id).toList(), ['first', 'second']);
    });

    test('rankSearchResults respects result limit', () {
      final songs = [
        _testSong('1', 'Heer', 'Afusic'),
        _testSong('2', 'Heer Remix', 'Afusic'),
        _testSong('3', 'Heer Live', 'Afusic'),
      ];

      final ranked = YouTubeSearchService.rankSearchResults(
        songs,
        'Heer Afusic',
        limit: 2,
      );

      expect(ranked, hasLength(2));
    });

    test('rankSearchResults returns empty for non-positive limit', () {
      final songs = [_testSong('1', 'Heer', 'Afusic')];

      expect(
        YouTubeSearchService.rankSearchResults(songs, 'Heer', limit: 0),
        isEmpty,
      );
    });
  });
}
