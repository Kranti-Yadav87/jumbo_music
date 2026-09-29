import '../models/song.dart';
import '../models/playlist.dart';

class MusicRepository {
  static const List<Song> sampleSongs = [];

  static final List<Song> newReleases = [
    Song(
      id: 'nr_1',
      title: 'Mero Mann',
      artist: 'B Praak, Mir Desai',
      album: 'Mero Mann - Single',
      genre: 'Devotional',
      duration: const Duration(minutes: 3, seconds: 52),
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
      coverUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600&auto=format&fit=crop&q=80',
    ),
    Song(
      id: 'nr_2',
      title: 'AUJLA SZN 1',
      artist: 'Karan Aujla',
      album: 'AUJLA SZN 1',
      genre: 'Desi hip-hop',
      duration: const Duration(minutes: 3, seconds: 18),
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&auto=format&fit=crop&q=80',
    ),
    Song(
      id: 'nr_3',
      title: 'Ghostface',
      artist: 'Sidhu Moose Wala, Mxrci',
      album: 'Ghostface',
      genre: 'Desi hip-hop',
      duration: const Duration(minutes: 4, seconds: 10),
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-12.mp3',
      coverUrl: 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=600&auto=format&fit=crop&q=80',
    ),
    Song(
      id: 'nr_4',
      title: 'Illuminati',
      artist: 'Sushin Shyam, Dabzee',
      album: 'Aavesham',
      genre: 'Dance & electronic',
      duration: const Duration(minutes: 3, seconds: 14),
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      coverUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600&auto=format&fit=crop&q=80',
    ),
    Song(
      id: 'nr_5',
      title: 'Tauba Tauba',
      artist: 'Karan Aujla',
      album: 'Bad Newz',
      genre: 'Pop',
      duration: const Duration(minutes: 3, seconds: 26),
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3',
      coverUrl: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=600&auto=format&fit=crop&q=80',
    ),
    Song(
      id: 'nr_6',
      title: 'Big Dawgs',
      artist: 'Hanumankind, Kalmi',
      album: 'Big Dawgs',
      genre: 'Desi hip-hop',
      duration: const Duration(minutes: 3, seconds: 40),
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3',
      coverUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600&auto=format&fit=crop&q=80',
    ),
  ];

  static final List<Playlist> samplePlaylists = [
    Playlist(
      id: 'p_90s_chill',
      title: '90s Chill: Bollywood',
      description: 'Anuradha Paudwal • Golden 90s Chill Hits',
      coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&auto=format&fit=crop&q=80',
      songIds: [],
    ),
    Playlist(
      id: 'p_90s_pop',
      title: "'90s Indian Pop",
      description: 'Daler Mehndi • Classic 90s Pop Revolution',
      coverUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=600&auto=format&fit=crop&q=80',
      songIds: [],
    ),
    Playlist(
      id: 'p_90s_tamil',
      title: '90s Sentiments - Tamil',
      description: 'Sujatha • Evergreen South Melodies',
      coverUrl: 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=600&auto=format&fit=crop&q=80',
      songIds: [],
    ),
    Playlist(
      id: '1134543272',
      title: 'India Superhits Top 50',
      description: 'Top 50 trending chartbusters across India (320 kbps Studio)',
      coverUrl: 'https://c.saavncdn.com/editorial/Hindi-IndiaSuperhitsTop50_20260911054516.jpg?bch=1790312747',
      songIds: [],
    ),
    Playlist(
      id: '110858205',
      title: 'Trending Today',
      description: 'Today\'s hottest streaming songs live from Aura/JioSaavn',
      coverUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600&auto=format&fit=crop&q=80',
      songIds: [],
    ),
    Playlist(
      id: '82914609',
      title: 'Best of Indie',
      description: 'Finest independent indie & acoustic releases',
      coverUrl: 'https://images.unsplash.com/photo-1465847899084-d164df4dedc6?w=600&auto=format&fit=crop&q=80',
      songIds: [],
    ),
    Playlist(
      id: '159470188',
      title: '90s Evergreen Duets',
      description: 'Golden era Bollywood duets & romantic memories',
      coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&auto=format&fit=crop&q=80',
      songIds: [],
    ),
    Playlist(
      id: 'p1',
      title: 'Late Night Lo-Fi',
      description: 'Relaxing beats, calm rain, study focus',
      coverUrl: 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?w=600&auto=format&fit=crop&q=80',
      songIds: [],
    ),
    Playlist(
      id: 'p2',
      title: 'Bollywood Sukoon',
      description: 'Soul-touching Hindi melodies & romantic vibes',
      coverUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600&auto=format&fit=crop&q=80',
      songIds: [],
    ),
  ];
}
