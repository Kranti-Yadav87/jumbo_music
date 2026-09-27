import 'song.dart';

enum PlaylistType {
  custom,
  smartMix,
  artistMix,
  genreMix,
  favorites,
  recentlyPlayed,
}

class Playlist {
  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final List<String> songIds;
  final List<Song> songs;
  final PlaylistType type;
  final DateTime createdAt;

  Playlist({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.songIds,
    this.songs = const [],
    this.type = PlaylistType.custom,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Playlist copyWith({
    String? id,
    String? title,
    String? description,
    String? coverUrl,
    List<String>? songIds,
    List<Song>? songs,
    PlaylistType? type,
    DateTime? createdAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      songIds: songIds ?? this.songIds,
      songs: songs ?? this.songs,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

