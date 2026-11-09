import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/config/app_config.dart';
import 'package:jumbo_music/services/api/youtube_search_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('YouTubeSearchService Unit Tests', () {
    test('Default YouTube API Key matches ytmusicapi constants', () {
      expect(
        AppConfig.youtubeApiKey,
        equals('AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30'),
      );
    });

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
  });
}
