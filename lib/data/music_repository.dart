import '../models/song.dart';
import '../models/playlist.dart';

class MusicRepository {
  static const List<Song> sampleSongs = [];

  static const List<Song> romanceEssentials = [
    Song(
      id: 'romance_kesariya',
      title: 'Kesariya',
      artist: 'Arijit Singh, Pritam',
      album: 'Brahmastra',
      coverUrl:
          'https://c.saavncdn.com/editorial/charts_HindiTopSongs_500x500.jpg',
      audioUrl: '',
      duration: Duration(seconds: 268),
    ),
    Song(
      id: 'romance_raataan',
      title: 'Raataan Lambiyan',
      artist: 'Jubin Nautiyal, Asees Kaur',
      album: 'Shershaah',
      coverUrl:
          'https://c.saavncdn.com/editorial/charts_HindiTopSongs_500x500.jpg',
      audioUrl: '',
      duration: Duration(seconds: 230),
    ),
    Song(
      id: 'romance_hawabanke',
      title: 'Hawa Banke',
      artist: 'Darshan Raval',
      album: 'Hawa Banke',
      coverUrl:
          'https://c.saavncdn.com/artists/Darshan_Raval_005_20230323062306_500x500.jpg',
      audioUrl: '',
      duration: Duration(seconds: 215),
    ),
  ];

  static final List<Song> newReleases = [];

  static final List<Playlist> samplePlaylists = [
    Playlist(
      id: 'p_hindi',
      title: 'Hindi Top Hits',
      description: 'Arijit Singh, Shreya Ghoshal, Pritam • Trending Bollywood',
      coverUrl:
          'https://c.saavncdn.com/editorial/charts_HindiTopSongs_500x500.jpg',
      songIds: [],
    ),
    Playlist(
      id: 'p_punjabi',
      title: 'Punjabi Superhits',
      description: 'Karan Aujla, Diljit Dosanjh, Sidhu Moose Wala, AP Dhillon',
      coverUrl:
          'https://c.saavncdn.com/editorial/charts_PunjabiTopSongs_500x500.jpg',
      songIds: [],
    ),
    Playlist(
      id: 'p_bhojpuri',
      title: 'Bhojpuri Dhamaka',
      description: 'Pawan Singh, Khesari Lal Yadav, Shilpi Raj • Chartbusters',
      coverUrl:
          'https://c.saavncdn.com/editorial/charts_BhojpuriTopSongs_500x500.jpg',
      songIds: [],
    ),
    Playlist(
      id: 'p_haryanvi',
      title: 'Haryanvi Hits',
      description: 'Gulzaar Chhaniwala, Renuka Panwar, Diler Kharkiya',
      coverUrl:
          'https://c.saavncdn.com/editorial/charts_HaryanviTopSongs_500x500.jpg',
      songIds: [],
    ),
    Playlist(
      id: 'p_english',
      title: 'English & Global Pop',
      description: 'Taylor Swift, The Weeknd, Drake, Dua Lipa • Billboard Top',
      coverUrl:
          'https://c.saavncdn.com/editorial/charts_EnglishTopSongs_500x500.jpg',
      songIds: [],
    ),
    Playlist(
      id: 'p_south',
      title: 'South Special (Tamil & Telugu)',
      description: 'Anirudh Ravichander, Sid Sriram, Devi Sri Prasad',
      coverUrl:
          'https://c.saavncdn.com/editorial/charts_TamilTopSongs_500x500.jpg',
      songIds: [],
    ),
    Playlist(
      id: 'p_indie',
      title: 'Indie & Acoustic Beats',
      description: 'Prateek Kuhad, Anuv Jain, Jasleen Royal • Pure Melodies',
      coverUrl:
          'https://c.saavncdn.com/editorial/BestOfIndieHindi_20230324103126_500x500.jpg',
      songIds: [],
    ),
    Playlist(
      id: 'p_sufi',
      title: 'Sufi & Qawwali Hits',
      description: 'Rahat Fateh Ali Khan, Atif Aslam, Nusrat Fateh Ali Khan',
      coverUrl:
          'https://c.saavncdn.com/editorial/SoulfulSufi_20210416065535_500x500.jpg',
      songIds: [],
    ),
  ];

  static final List<Playlist> featuredPlaylistsForYou = [
    Playlist(
      id: 'fp_daily_mix',
      title: 'Daily Mix For You',
      description: 'Personalized mix • Trending Bollywood & Global Pop',
      coverUrl:
          'https://c.saavncdn.com/editorial/charts_HindiTopSongs_500x500.jpg',
      songIds: [],
    ),
    Playlist(
      id: 'fp_global_top50',
      title: 'Global & Bollywood Top 50',
      description: 'Arijit, Taylor Swift, The Weeknd, Diljit, Ed Sheeran',
      coverUrl:
          'https://c.saavncdn.com/editorial/charts_EnglishTopSongs_500x500.jpg',
      songIds: [],
    ),
    Playlist(
      id: 'fp_late_night',
      title: 'Late Night Chill & Drive',
      description: 'Slowed & Reverb, Lofi Chill, Melancholy Beats',
      coverUrl:
          'https://c.saavncdn.com/editorial/BestOfIndieHindi_20230324103126_500x500.jpg',
      songIds: [],
    ),
    Playlist(
      id: 'fp_viral_2026',
      title: 'Viral Hits 2026',
      description: 'Internet chartbusters & trending social anthems',
      coverUrl:
          'https://c.saavncdn.com/editorial/charts_PunjabiTopSongs_500x500.jpg',
      songIds: [],
    ),
    Playlist(
      id: 'fp_acoustic',
      title: 'Acoustic Coffeehouse',
      description: 'Soulful acoustic guitars, unplugged & soothing vibes',
      coverUrl:
          'https://c.saavncdn.com/editorial/SoulfulSufi_20210416065535_500x500.jpg',
      songIds: [],
    ),
  ];

  static const List<Map<String, String>> popularArtists = [
    {
      'id': 'art_darshan',
      'name': 'Darshan Raval',
      'role': 'Heartthrob of Indie & Romance',
      'listeners': '33M+ monthly streams',
      'imageUrl':
          'https://c.saavncdn.com/artists/Darshan_Raval_005_20230323062306_500x500.jpg',
      'query': 'Darshan Raval romantic hits',
      'keywords':
          'darshan raval dharshan rawal darshan rawal dharshan raval kamariya chogada',
    },
    {
      'id': 'art_taylorswift',
      'name': 'Taylor Swift',
      'role': 'Global Pop Phenomenon',
      'listeners': '105M+ monthly streams',
      'imageUrl':
          'https://c.saavncdn.com/artists/Taylor_Swift_003_20200827170119_500x500.jpg',
      'query': 'Taylor Swift hits',
      'keywords':
          'taylor swift cruel summer blank space love story shake it off anti hero',
    },
    {
      'id': 'art_arijit',
      'name': 'Arijit Singh',
      'role': 'King of Soulful Melodies',
      'listeners': '42M+ monthly streams',
      'imageUrl':
          'https://c.saavncdn.com/artists/Arijit_Singh_002_20230323062147_500x500.jpg',
      'query': 'Arijit Singh hits',
      'keywords': 'arijit singh arijit romantic hits tum hi ho kesariya',
    },
    {
      'id': 'art_theweeknd',
      'name': 'The Weeknd',
      'role': 'King of R&B & Synthwave',
      'listeners': '110M+ monthly streams',
      'imageUrl':
          'https://c.saavncdn.com/artists/The_Weeknd_003_20230323062635_500x500.jpg',
      'query': 'The Weeknd hits',
      'keywords':
          'the weeknd abel blinding lights starboy save your tears die for you',
    },
    {
      'id': 'art_edsheeran',
      'name': 'Ed Sheeran',
      'role': 'Global Acoustic Pop Superstar',
      'listeners': '88M+ monthly streams',
      'imageUrl':
          'https://c.saavncdn.com/artists/Ed_Sheeran_003_20230323062615_500x500.jpg',
      'query': 'Ed Sheeran hits',
      'keywords':
          'ed sheeran shape of you perfect thinking out loud bad habits',
    },
    {
      'id': 'art_jubin',
      'name': 'Jubin Nautiyal',
      'role': 'Soulful & Devotional Maestro',
      'listeners': '27M+ monthly streams',
      'imageUrl':
          'https://c.saavncdn.com/artists/Jubin_Nautiyal_003_20230323062348_500x500.jpg',
      'query': 'Jubin Nautiyal hits',
      'keywords': 'jubin nautiyal jubin hits raataan lambiyan lut gaye',
    },
    {
      'id': 'art_justinbieber',
      'name': 'Justin Bieber',
      'role': 'Global Pop Legend',
      'listeners': '82M+ monthly streams',
      'imageUrl':
          'https://c.saavncdn.com/artists/Justin_Bieber_003_20230323062650_500x500.jpg',
      'query': 'Justin Bieber hits',
      'keywords': 'justin bieber stay baby peaches ghost sorry',
    },
    {
      'id': 'art_karan',
      'name': 'Karan Aujla',
      'role': 'Singer & Lyricist',
      'listeners': '28M+ monthly streams',
      'imageUrl':
          'https://c.saavncdn.com/artists/Karan_Aujla_004_20230609071019_500x500.jpg',
      'query': 'Karan Aujla hits',
      'keywords': 'karan aujla aujla tauba tauba winning speech',
    },
    {
      'id': 'art_billieeilish',
      'name': 'Billie Eilish',
      'role': 'Alt-Pop Innovator',
      'listeners': '76M+ monthly streams',
      'imageUrl':
          'https://c.saavncdn.com/artists/Billie_Eilish_003_20230323062725_500x500.jpg',
      'query': 'Billie Eilish hits',
      'keywords': 'billie eilish bad guy lovely birds of a feather ocean eyes',
    },
    {
      'id': 'art_diljit',
      'name': 'Diljit Dosanjh',
      'role': 'Global Punjabi Icon',
      'listeners': '34M+ monthly streams',
      'imageUrl':
          'https://c.saavncdn.com/artists/Diljit_Dosanjh_004_20221006184540_500x500.jpg',
      'query': 'Diljit Dosanjh hits',
      'keywords': 'diljit dosanjh diljit goat born to shine lover',
    },
    {
      'id': 'art_dualipa',
      'name': 'Dua Lipa',
      'role': 'Queen of Modern Disco Pop',
      'listeners': '74M+ monthly streams',
      'imageUrl':
          'https://c.saavncdn.com/artists/Dua_Lipa_003_20230323062740_500x500.jpg',
      'query': 'Dua Lipa hits',
      'keywords': 'dua lipa levitating don\'t start now new rules houdini',
    },
    {
      'id': 'art_shreya',
      'name': 'Shreya Ghoshal',
      'role': 'Melody Queen of India',
      'listeners': '30M+ monthly streams',
      'imageUrl':
          'https://c.saavncdn.com/artists/Shreya_Ghoshal_004_20230323061447_500x500.jpg',
      'query': 'Shreya Ghoshal hits',
      'keywords': 'shreya ghoshal shreya shreya hits deewani mastani',
    },
    {
      'id': 'art_brunomars',
      'name': 'Bruno Mars',
      'role': 'Funk & Soul Pop King',
      'listeners': '78M+ monthly streams',
      'imageUrl':
          'https://c.saavncdn.com/artists/Bruno_Mars_003_20230323062800_500x500.jpg',
      'query': 'Bruno Mars hits',
      'keywords':
          'bruno mars uptown funk die with a smile 24k magic locked out of heaven',
    },
    {
      'id': 'art_kk',
      'name': 'KK (Krishnakumar Kunnath)',
      'role': 'Voice of a Generation',
      'listeners': '27M+ monthly streams',
      'imageUrl': 'https://c.saavncdn.com/artists/KK_500x500.jpg',
      'query': 'KK hits',
      'keywords': 'kk krishnakumar kunnath kya mujhe pyar hai zara sa alvida',
    },
    {
      'id': 'art_drake',
      'name': 'Drake',
      'role': 'Global Hip-Hop & Rap Icon',
      'listeners': '84M+ monthly streams',
      'imageUrl':
          'https://c.saavncdn.com/artists/Drake_003_20230323062815_500x500.jpg',
      'query': 'Drake hits',
      'keywords': 'drake one dance hotline bling god\'s plan passionfruit',
    },
    {
      'id': 'art_sidhu',
      'name': 'Sidhu Moose Wala',
      'role': 'Legendary Punjabi Icon',
      'listeners': '31M+ monthly streams',
      'imageUrl':
          'https://c.saavncdn.com/artists/Sidhu_Moose_Wala_004_20230607074218_500x500.jpg',
      'query': 'Sidhu Moose Wala hits',
      'keywords': 'sidhu moose wala sidhu moosewala 295 so high',
    },
    {
      'id': 'art_postmalone',
      'name': 'Post Malone',
      'role': 'Genre-Blending Superstar',
      'listeners': '70M+ monthly streams',
      'imageUrl':
          'https://c.saavncdn.com/artists/Post_Malone_003_20230323062835_500x500.jpg',
      'query': 'Post Malone hits',
      'keywords': 'post malone sunflower circles rockstar congratulations',
    },
    {
      'id': 'art_anirudh',
      'name': 'Anirudh Ravichander',
      'role': 'Rockstar Music Director',
      'listeners': '29M+ monthly streams',
      'imageUrl':
          'https://c.saavncdn.com/artists/Anirudh_Ravichander_002_20230328080355_500x500.jpg',
      'query': 'Anirudh Ravichander hits',
      'keywords': 'anirudh ravichander anirudh leo jailer hukuum arabic kuthu',
    },
    {
      'id': 'art_arianagrande',
      'name': 'Ariana Grande',
      'role': 'Vocal Queen & Pop Icon',
      'listeners': '75M+ monthly streams',
      'imageUrl':
          'https://c.saavncdn.com/artists/Ariana_Grande_003_20230323062855_500x500.jpg',
      'query': 'Ariana Grande hits',
      'keywords':
          'ariana grande 7 rings thank u next side to side we can\'t be friends',
    },
    {
      'id': 'art_atif',
      'name': 'Atif Aslam',
      'role': 'Romantic Vocalist',
      'listeners': '26M+ monthly streams',
      'imageUrl':
          'https://c.saavncdn.com/artists/Atif_Aslam_002_20210217084534_500x500.jpg',
      'query': 'Atif Aslam hits',
      'keywords': 'atif aslam atif aadat tere bin pehli nazar mein',
    },
    {
      'id': 'art_coldplay',
      'name': 'Coldplay',
      'role': 'Legendary Global Rock Band',
      'listeners': '68M+ monthly streams',
      'imageUrl':
          'https://c.saavncdn.com/artists/Coldplay_003_20230323062915_500x500.jpg',
      'query': 'Coldplay hits',
      'keywords':
          'coldplay yellow viva la vida hymn for the weekend paradise a sky full of stars',
    },
    {
      'id': 'art_alanwalker',
      'name': 'Alan Walker',
      'role': 'Global Electronic & EDM Star',
      'listeners': '48M+ monthly streams',
      'imageUrl':
          'https://c.saavncdn.com/artists/Alan_Walker_003_20230323062935_500x500.jpg',
      'query': 'Alan Walker hits',
      'keywords': 'alan walker faded alone on my way the spectre darkside',
    },
    {
      'id': 'art_kishore',
      'name': 'Kishore Kumar',
      'role': 'Evergreen Legend of Golden Era',
      'listeners': '35M+ monthly streams',
      'imageUrl': 'https://c.saavncdn.com/artists/Kishore_Kumar_500x500.jpg',
      'query': 'Kishore Kumar evergreen romantic hits',
      'keywords':
          'kishore kumar kishore da purane gaane roop tera mastana mere sapno ki rani',
    },
    {
      'id': 'art_charlieputh',
      'name': 'Charlie Puth',
      'role': 'Pop Maestro & Pitch Perfect',
      'listeners': '52M+ monthly streams',
      'imageUrl':
          'https://c.saavncdn.com/artists/Charlie_Puth_003_20230323062955_500x500.jpg',
      'query': 'Charlie Puth hits',
      'keywords':
          'charlie puth see you again attention we don\'t talk anymore left and right',
    },
    {
      'id': 'art_lata',
      'name': 'Lata Mangeshkar',
      'role': 'Nightingale of India',
      'listeners': '38M+ monthly streams',
      'imageUrl': 'https://c.saavncdn.com/artists/Lata_Mangeshkar_500x500.jpg',
      'query': 'Lata Mangeshkar golden era hits',
      'keywords':
          'lata mangeshkar lata ji aaja piya tohe pyar doon lag ja gale purane gaane',
    },
    {
      'id': 'art_selenagomez',
      'name': 'Selena Gomez',
      'role': 'Global Pop Sensation',
      'listeners': '55M+ monthly streams',
      'imageUrl':
          'https://c.saavncdn.com/artists/Selena_Gomez_003_20230323063015_500x500.jpg',
      'query': 'Selena Gomez hits',
      'keywords':
          'selena gomez calm down lose you to love me wolves love you like a love song',
    },
    {
      'id': 'art_zayn',
      'name': 'Zayn Malik',
      'role': 'R&B & Pop Vocalist',
      'listeners': '42M+ monthly streams',
      'imageUrl':
          'https://c.saavncdn.com/artists/Zayn_003_20230323063035_500x500.jpg',
      'query': 'Zayn hits',
      'keywords':
          'zayn malik zayn dusk till dawn pillowtalk let me i don\'t wanna live forever',
    },
    {
      'id': 'art_eminem',
      'name': 'Eminem',
      'role': 'Rap God & Global Legend',
      'listeners': '68M+ monthly streams',
      'imageUrl':
          'https://c.saavncdn.com/artists/Eminem_003_20230323063055_500x500.jpg',
      'query': 'Eminem hits',
      'keywords':
          'eminem rap god lose yourself love the way you lie without me not afraid',
    },
    {
      'id': 'art_rafi',
      'name': 'Mohammed Rafi',
      'role': 'Soul of Indian Cinema',
      'listeners': '32M+ monthly streams',
      'imageUrl': 'https://c.saavncdn.com/artists/Mohammed_Rafi_500x500.jpg',
      'query': 'Mohammed Rafi classic romantic hits',
      'keywords':
          'mohammed rafi mohd rafi rafi sahab purane gaane gulabi aankhen',
    },
    {
      'id': 'art_kumarsanu',
      'name': 'Kumar Sanu',
      'role': 'King of 90s Melodies',
      'listeners': '29M+ monthly streams',
      'imageUrl': 'https://c.saavncdn.com/artists/Kumar_Sanu_500x500.jpg',
      'query': 'Kumar Sanu 90s romantic hits',
      'keywords': 'kumar sanu 90s melodies tujhe dekha to chura ke dil mera',
    },
    {
      'id': 'art_alkayagnik',
      'name': 'Alka Yagnik',
      'role': '90s Melody Queen',
      'listeners': '31M+ monthly streams',
      'imageUrl': 'https://c.saavncdn.com/artists/Alka_Yagnik_500x500.jpg',
      'query': 'Alka Yagnik 90s superhits',
      'keywords': 'alka yagnik 90s hits tip tip barsa paani kuch kuch hota hai',
    },
    {
      'id': 'art_sonunigam',
      'name': 'Sonu Nigam',
      'role': 'Lord of Vocals',
      'listeners': '25M+ monthly streams',
      'imageUrl': 'https://c.saavncdn.com/artists/Sonu_Nigam_500x500.jpg',
      'query': 'Sonu Nigam romantic hits',
      'keywords':
          'sonu nigam kal ho naa ho abhi mujh mein kahin sandese aate hai',
    },
    {
      'id': 'art_apdhillon',
      'name': 'AP Dhillon',
      'role': 'Punjabi Wave Leader',
      'listeners': '22M+ monthly streams',
      'imageUrl':
          'https://c.saavncdn.com/artists/AP_Dhillon_002_20220623062306_500x500.jpg',
      'query': 'AP Dhillon hits',
      'keywords': 'ap dhillon brown munde excels with you insane',
    },
    {
      'id': 'art_badshah',
      'name': 'Badshah',
      'role': 'Desi Hip-Hop & Commercial King',
      'listeners': '26M+ monthly streams',
      'imageUrl':
          'https://c.saavncdn.com/artists/Badshah_005_20230323061803_500x500.jpg',
      'query': 'Badshah party hits',
      'keywords': 'badshah genda phool jugnu kala chashma dj wale babu',
    },
    {
      'id': 'art_nehakakkar',
      'name': 'Neha Kakkar',
      'role': 'Pop & Party Sensation',
      'listeners': '24M+ monthly streams',
      'imageUrl':
          'https://c.saavncdn.com/artists/Neha_Kakkar_006_20230323061614_500x500.jpg',
      'query': 'Neha Kakkar hits',
      'keywords': 'neha kakkar aankh marey dilbar mile ho tum',
    },
    {
      'id': 'art_honeysingh',
      'name': 'Yo Yo Honey Singh',
      'role': 'OG Desi Hip-Hop Star',
      'listeners': '25M+ monthly streams',
      'imageUrl':
          'https://c.saavncdn.com/artists/Yo_Yo_Honey_Singh_002_20230323061849_500x500.jpg',
      'query': 'Honey Singh hits',
      'keywords':
          'yo yo honey singh honey singh desi kalakaar love dose blue eyes',
    },
    {
      'id': 'art_armaan',
      'name': 'Armaan Malik',
      'role': 'Prince of Modern Romance',
      'listeners': '20M+ monthly streams',
      'imageUrl':
          'https://c.saavncdn.com/artists/Armaan_Malik_004_20230323062228_500x500.jpg',
      'query': 'Armaan Malik romantic hits',
      'keywords': 'armaan malik bol do na zara main hoon hero tera butta bomma',
    },
    {
      'id': 'art_vishalmishra',
      'name': 'Vishal Mishra',
      'role': 'Soul & Passionate Vocalist',
      'listeners': '21M+ monthly streams',
      'imageUrl':
          'https://c.saavncdn.com/artists/Vishal_Mishra_003_20230323062432_500x500.jpg',
      'query': 'Vishal Mishra hits',
      'keywords': 'vishal mishra pehle bhi main kaise hua zihaal e miskin',
    },
    {
      'id': 'art_sunidhi',
      'name': 'Sunidhi Chauhan',
      'role': 'Powerhouse Diva',
      'listeners': '19M+ monthly streams',
      'imageUrl':
          'https://c.saavncdn.com/artists/Sunidhi_Chauhan_003_20230323061528_500x500.jpg',
      'query': 'Sunidhi Chauhan hits',
      'keywords': 'sunidhi chauhan kamli beedi crazy kiya re',
    },
    {
      'id': 'art_mohitchauhan',
      'name': 'Mohit Chauhan',
      'role': 'Soul of Rockstar & Melodies',
      'listeners': '18M+ monthly streams',
      'imageUrl':
          'https://c.saavncdn.com/artists/Mohit_Chauhan_003_20230323062512_500x500.jpg',
      'query': 'Mohit Chauhan hits',
      'keywords':
          'mohit chauhan tum se hi kun faya kun saadda haq naadan parindey',
    },
    {
      'id': 'art_jagjit',
      'name': 'Jagjit Singh',
      'role': 'King of Ghazals',
      'listeners': '20M+ monthly streams',
      'imageUrl': 'https://c.saavncdn.com/artists/Jagjit_Singh_500x500.jpg',
      'query': 'Jagjit Singh ghazals',
      'keywords':
          'jagjit singh ghazals hothon se chhu lo tum tum itna jo muskura rahe ho',
    },
    {
      'id': 'art_pawan',
      'name': 'Pawan Singh',
      'role': 'Bhojpuri Powerstar',
      'listeners': '22M+ monthly streams',
      'imageUrl':
          'https://c.saavncdn.com/artists/Pawan_Singh_002_20230323063544_500x500.jpg',
      'query': 'Pawan Singh hits',
      'keywords': 'pawan singh bhojpuri lollipop lagelu kamariya patre patre',
    },
  ];
}
