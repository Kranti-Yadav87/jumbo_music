import 'package:flutter_test/flutter_test.dart';
import 'package:http_parser/http_parser.dart';
import 'package:jumbo_music/models/song.dart';
import 'package:jumbo_music/services/api/youtube_search_service.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:youtube_explode_dart/src/videos/streams/models/audio_track.dart';

AudioOnlyStreamInfo _audioOnlyStream({
  required int tag,
  required String container,
  required String audioCodec,
  required int bitrate,
  bool isDefault = true,
}) {
  final streamContainer = container == 'mp4'
      ? StreamContainer.mp4
      : StreamContainer.webM;

  return AudioOnlyStreamInfo(
    VideoId('gD4EtH2Plik'),
    tag,
    Uri.parse('https://example.com/audio/$tag'),
    streamContainer,
    const FileSize(1024),
    Bitrate(bitrate),
    audioCodec,
    'audio',
    const [],
    MediaType('audio', container),
    AudioTrack(displayName: 'English', id: 'en', audioIsDefault: isDefault),
  );
}

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
      expect(songs.first.artist, 'Unknown Artist');
      expect(songs.first.uploaderName, 'Sidhu Moose Wala');
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
      expect(songs.first.artist, 'Unknown Artist');
      expect(songs.first.duration, Duration.zero);
      expect(YouTubeSearchService.parseDataApiSearchResults({}), isEmpty);
    });

    test('parseDataApiSearchResults parses Smart Music metadata', () {
      final songs = YouTubeSearchService.parseDataApiSearchResults({
        'items': [
          {
            'videoId': 'gD4EtH2Plik',
            'title': 'Heer',
            'channelTitle': 'Afusic',
            'durationSeconds': 197,
            'viewCount': 1250000,
            'likeCount': 45000,
            'description': 'Official audio of Heer',
            'tags': ['Heer', 'Afusic', '', 123, 'Punjabi Song'],
            'categoryId': '10',
            'channelId': 'UC123456789',
          },
        ],
      });

      expect(songs, hasLength(1));
      final song = songs.first;

      expect(song.artist, 'Unknown Artist');
      expect(song.uploaderName, 'Afusic');
      expect(song.viewCount, 1250000);
      expect(song.likeCount, 45000);
      expect(song.description, 'Official audio of Heer');
      expect(song.tags, ['Heer', 'Afusic', 'Punjabi Song']);
      expect(song.categoryId, '10');
      expect(song.channelId, 'UC123456789');
    });

    test(
      'parseDataApiSearchResults safely defaults missing and negative metadata',
      () {
        final songs = YouTubeSearchService.parseDataApiSearchResults({
          'items': [
            {'videoId': 'gD4EtH2Plik', 'title': 'Missing metadata'},
            {
              'videoId': 'mOB1S1qXcPQ',
              'title': 'Negative metadata',
              'viewCount': -100,
              'likeCount': '-50',
              'description': '',
              'tags': ['  ', 123],
            },
          ],
        });

        expect(songs, hasLength(2));

        final missing = songs[0];
        expect(missing.viewCount, 0);
        expect(missing.likeCount, 0);
        expect(missing.description, '');
        expect(missing.tags, isEmpty);
        expect(missing.categoryId, '');
        expect(missing.channelId, '');

        final negative = songs[1];
        expect(negative.viewCount, 0);
        expect(negative.likeCount, 0);
        expect(negative.tags, isEmpty);
      },
    );

    test('alternate stream selection prefers AAC and excludes failed itag', () {
      final failedOpus = _audioOnlyStream(
        tag: 251,
        container: 'webm',
        audioCodec: 'opus',
        bitrate: 143250,
      );
      final lowerBitrateOpus = _audioOnlyStream(
        tag: 249,
        container: 'webm',
        audioCodec: 'opus',
        bitrate: 55250,
      );
      final aac = _audioOnlyStream(
        tag: 140,
        container: 'mp4',
        audioCodec: 'mp4a.40.2',
        bitrate: 127450,
      );

      final selected = YouTubeSearchService.selectAlternateAudioStream(
        [failedOpus, lowerBitrateOpus, aac],
        excludeTag: 251,
        failedContainer: 'webm',
      );

      expect(selected?.tag, 140);
    });

    test(
      'alternate stream selection returns null without another container',
      () {
        final streams = [
          _audioOnlyStream(
            tag: 251,
            container: 'webm',
            audioCodec: 'opus',
            bitrate: 143250,
          ),
          _audioOnlyStream(
            tag: 249,
            container: 'webm',
            audioCodec: 'opus',
            bitrate: 55250,
          ),
        ];

        expect(
          YouTubeSearchService.selectAlternateAudioStream(
            streams,
            excludeTag: 251,
            failedContainer: 'webm',
          ),
          isNull,
        );
      },
    );

    test('alternate stream selection ignores non-default audio tracks', () {
      final streams = [
        _audioOnlyStream(
          tag: 140,
          container: 'mp4',
          audioCodec: 'mp4a.40.2',
          bitrate: 127450,
          isDefault: false,
        ),
      ];

      expect(
        YouTubeSearchService.selectAlternateAudioStream(
          streams,
          excludeTag: 251,
          failedContainer: 'webm',
        ),
        isNull,
      );
    });

    test('normalizeQuery preserves title and artist connectors', () {
      expect(
        YouTubeSearchService.normalizeQuery('Heer by afusic'),
        equals('Heer by afusic'),
      );
      expect(
        YouTubeSearchService.normalizeQuery('afusic song'),
        equals('afusic'),
      );
      expect(
        YouTubeSearchService.normalizeQuery('dil by afusic official video'),
        equals('dil by afusic'),
      );
      expect(
        YouTubeSearchService.normalizeQuery('shape of you by ed sheeran'),
        equals('shape of you by ed sheeran'),
      );
      expect(
        YouTubeSearchService.normalizeQuery('Stand By Me'),
        equals('Stand By Me'),
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
