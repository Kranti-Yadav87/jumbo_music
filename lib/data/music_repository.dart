import '../models/song.dart';
import '../models/playlist.dart';

class MusicRepository {
  static final List<Song> sampleSongs = [
    Song(
      id: '1',
      title: 'Kesariya Sukoon',
      artist: 'Arijit & Jumbo Crew',
      album: 'Bollywood Melodies',
      genre: 'Bollywood',
      duration: const Duration(minutes: 4, seconds: 28),
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      coverUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600&auto=format&fit=crop&q=80',
      lyrics: '''
(Intro Melody - Flute & Sitar)
Mujhko itna bata de koi
Kaisi ye bekhudi chhayi hai
Teri aahat se saansein chalein
Dhadkan me tu hi samayi hai...

Kesariya tera ishq hai piya
Rang jaaun jo main haath lagaun
Din beete saara teri fikar me
Rain saari tere sapno me bitaun

(Violin Chorus)
O re piya re, tera bina main aadha
Haan baandh liya dil se tera ye vaada...
''',
    ),
    Song(
      id: '2',
      title: 'Midnight Lo-Fi Chill',
      artist: 'Kranti Beats',
      album: 'Lofi Study Session Vol. 1',
      genre: 'Lo-Fi',
      duration: const Duration(minutes: 7, seconds: 5),
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      coverUrl: 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?w=600&auto=format&fit=crop&q=80',
      lyrics: '''
[Instrumental Lo-Fi Rain & Vinyl Crackle]

Coffee cup warm in my hands
Watching raindrops trace the glass
Late night city softly stands
Letting midnight memories pass...

[Smooth Rhodes Piano & Soft Drum Beat]
Just keep drifting...
Just keep breathing...
In the rhythm of the quiet night.
''',
    ),
    Song(
      id: '3',
      title: 'Neon Nights (Cyber Wave)',
      artist: 'DJ Jumbo',
      album: 'Synthwave Horizons',
      genre: 'EDM',
      duration: const Duration(minutes: 5, seconds: 45),
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      coverUrl: 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=600&auto=format&fit=crop&q=80',
      lyrics: '''
Speeding down the neon strip
Fast lane running in the dark
Electric pulse in every step
Igniting every neon spark...

Turn the bass up higher now!
Feel the lasers touch the sky!
We will never shut it down
Dancing till the morning light!
''',
    ),
    Song(
      id: '4',
      title: 'Tere Bina Acoustic',
      artist: 'Kabir & Sanaya',
      album: 'Acoustic Coffeehouse',
      genre: 'Acoustic',
      duration: const Duration(minutes: 5, seconds: 2),
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
      coverUrl: 'https://images.unsplash.com/photo-1465847899084-d164df4dedc6?w=600&auto=format&fit=crop&q=80',
      lyrics: '''
(Nylon Guitar Fingerpicking)

Tere bina lagta nahi dil
Har subah ban gayi mushkil
Haath thama tha jahan tune
Wahin theher gayi manzil...

Kyun khamoshi me teri hi aawaaz aati hai?
Har hawa tera hi paigham laati hai...
O sanware, laut aao re...
''',
    ),
    Song(
      id: '5',
      title: 'Sunset Horizon',
      artist: 'Aura Collective',
      album: 'Deep Chillout',
      genre: 'Chill',
      duration: const Duration(minutes: 6, seconds: 12),
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3',
      coverUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600&auto=format&fit=crop&q=80',
      lyrics: '''
Golden horizon fading low
Waves whispering soft and slow
Leave your heavy bags behind
Peace of mind is what you find.

Sail into the amber sun
Where the ocean and sky become one...
''',
    ),
    Song(
      id: '6',
      title: 'Dil Ki Dhadkan (Pop Groove)',
      artist: 'Riya Sen ft. Jumbo',
      album: 'Urban Desi Pop',
      genre: 'Pop',
      duration: const Duration(minutes: 4, seconds: 35),
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3',
      coverUrl: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=600&auto=format&fit=crop&q=80',
      lyrics: '''
Kaisi yeh dastan
Khoya mera aasmaan
Jab se tujhse nazar mili
Badal gaya mera jahan...

Dil ki dhadkan tez huyi
Baaton me teri meethi shararat hai
Hum toh kabke kho chuke
Ab bas teri hi aadat hai!
''',
    ),
    Song(
      id: '7',
      title: 'Rainy Cafe Vibes',
      artist: 'Mellow Moon',
      album: 'Study & Work Lo-Fi',
      genre: 'Lo-Fi',
      duration: const Duration(minutes: 6, seconds: 50),
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-10.mp3',
      coverUrl: 'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?w=600&auto=format&fit=crop&q=80',
      lyrics: '''
[Ambient Coffee Shop chatter & raindrops]
Keys typing smoothly...
Sipping warm cinnamon chai...
No rush, no worries...
Just you and your ideas flying high.
''',
    ),
    Song(
      id: '8',
      title: 'Apex Energy Workout',
      artist: 'Pulse Velocity',
      album: 'Gym Beast Mode',
      genre: 'EDM',
      duration: const Duration(minutes: 5, seconds: 20),
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-12.mp3',
      coverUrl: 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=600&auto=format&fit=crop&q=80',
      lyrics: '''
One more rep, push the line!
Champions don't wait for time!
Feel the adrenaline through your veins
No easy shortcut, conquer the pain!

Level UP!
Don't you stop now!
Break the ceiling, own the ground!
''',
    ),
  ];

  static final List<Playlist> samplePlaylists = [
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
      songIds: ['2', '7'],
    ),
    Playlist(
      id: 'p2',
      title: 'Bollywood Sukoon',
      description: 'Soul-touching Hindi melodies & romantic vibes',
      coverUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600&auto=format&fit=crop&q=80',
      songIds: ['1', '4', '6'],
    ),
  ];

  static final List<String> genres = [
    'All',
    'Bollywood',
    'Lo-Fi',
    'EDM',
    'Acoustic',
    'Chill',
    'Pop',
  ];
}
