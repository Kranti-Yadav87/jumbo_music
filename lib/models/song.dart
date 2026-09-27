class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final String audioUrl;
  final String coverUrl;
  final String genre;
  final String lyrics;
  final bool isFavorite;
  final String releaseYear;
  final String quality;
  final bool isLiveStream;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    this.album = 'Single',
    required this.duration,
    required this.audioUrl,
    required this.coverUrl,
    this.genre = 'Pop',
    this.lyrics = '',
    this.isFavorite = false,
    this.releaseYear = '2026',
    this.quality = '320 kbps HD',
    this.isLiveStream = false,
  });

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    Duration? duration,
    String? audioUrl,
    String? coverUrl,
    String? genre,
    String? lyrics,
    bool? isFavorite,
    String? releaseYear,
    String? quality,
    bool? isLiveStream,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      audioUrl: audioUrl ?? this.audioUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      genre: genre ?? this.genre,
      lyrics: lyrics ?? this.lyrics,
      isFavorite: isFavorite ?? this.isFavorite,
      releaseYear: releaseYear ?? this.releaseYear,
      quality: quality ?? this.quality,
      isLiveStream: isLiveStream ?? this.isLiveStream,
    );
  }

  String get formattedDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
