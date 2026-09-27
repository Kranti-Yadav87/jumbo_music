class Playlist {
  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final List<String> songIds;

  const Playlist({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.songIds,
  });
}
