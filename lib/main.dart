import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(const JumboMusicApp());
}

class JumboMusicApp extends StatelessWidget {
  const JumboMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jumbo Music',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
      ),
      home: const HomeScreen(),
    );
  }
}

class Song {
  final String title;
  final String artist;
  final String url;
  final String image;

  Song({
    required this.title,
    required this.artist,
    required this.url,
    required this.image,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final player = AudioPlayer();

  int currentIndex = -1;
  bool isPlaying = false;

  final List<Song> songs = [
    Song(
      title: "Chill Beat",
      artist: "Kranti",
      url:
          "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
      image:
          "https://picsum.photos/300?1",
    ),
    Song(
      title: "Night Vibes",
      artist: "Jumbo",
      url:
          "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3",
      image:
          "https://picsum.photos/300?2",
    ),
    Song(
      title: "LoFi Dreams",
      artist: "Jumbo",
      url:
          "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3",
      image:
          "https://picsum.photos/300?3",
    ),
  ];

  @override
  void initState() {
    super.initState();

    player.playerStateStream.listen((state) {
      setState(() {
        isPlaying = state.playing;
      });

      if (state.processingState == ProcessingState.completed) {
        nextSong();
      }
    });
  }

  Future<void> playSong(int index) async {
    currentIndex = index;

    await player.setUrl(songs[index].url);

    await player.play();

    setState(() {});
  }

  void togglePlay() {
    if (isPlaying) {
      player.pause();
    } else {
      player.play();
    }
  }

  void nextSong() {
    if (songs.isEmpty) return;

    int nextIndex = currentIndex + 1;

    if (nextIndex >= songs.length) {
      nextIndex = 0;
    }

    playSong(nextIndex);
  }

  void previousSong() {
    if (songs.isEmpty) return;

    int prevIndex = currentIndex - 1;

    if (prevIndex < 0) {
      prevIndex = songs.length - 1;
    }

    playSong(prevIndex);
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "JUMBO MUSIC",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A1A),
              Color(0xFF000000),
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];

                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          song.image,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(
                        song.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(song.artist),
                      trailing: Icon(
                        currentIndex == index && isPlaying
                            ? Icons.equalizer
                            : Icons.play_arrow,
                      ),
                      onTap: () {
                        playSong(index);
                      },
                    ),
                  );
                },
              ),
            ),

            if (currentIndex != -1)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        songs[currentIndex].image,
                        width: 65,
                        height: 65,
                        fit: BoxFit.cover,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            songs[currentIndex].title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            songs[currentIndex].artist,
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      onPressed: previousSong,
                      icon: const Icon(Icons.skip_previous),
                    ),

                    IconButton(
                      onPressed: togglePlay,
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_fill,
                        size: 42,
                      ),
                    ),

                    IconButton(
                      onPressed: nextSong,
                      icon: const Icon(Icons.skip_next),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}