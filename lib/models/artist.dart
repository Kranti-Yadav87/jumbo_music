class Artist {
  final String id;
  final String name;
  final String imageUrl;
  final String role;
  final String monthlyListeners;

  const Artist({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.role = 'Singer & Composer',
    this.monthlyListeners = '12M+ monthly streams',
  });
}
