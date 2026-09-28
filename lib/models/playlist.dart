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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'coverUrl': coverUrl,
      'songIds': songIds,
      'songs': songs.map((s) => s.toJson()).toList(),
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    PlaylistType pType = PlaylistType.custom;
    final typeName = json['type'] as String?;
    if (typeName != null) {
      for (final val in PlaylistType.values) {
        if (val.name == typeName) {
          pType = val;
          break;
        }
      }
    }

    final rawSongs = json['songs'] as List?;
    final List<Song> songList = [];
    if (rawSongs != null) {
      for (final item in rawSongs) {
        if (item is Map<String, dynamic>) {
          songList.add(Song.fromJson(item));
        }
      }
    }

    final rawSongIds = json['songIds'] as List?;
    final List<String> sIds = [];
    if (rawSongIds != null) {
      for (final id in rawSongIds) {
        if (id is String) sIds.add(id);
      }
    }

    return Playlist(
      id: json['id'] as String? ?? 'p_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] as String? ?? 'Custom Playlist',
      description: json['description'] as String? ?? '',
      coverUrl: json['coverUrl'] as String? ?? '',
      songIds: sIds,
      songs: songList,
      type: pType,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}


