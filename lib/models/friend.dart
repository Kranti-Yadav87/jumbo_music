class Friend {
  final String id;
  final String name;
  final String email;
  final String avatarInitials;
  final String currentSongTitle;
  final String currentSongArtist;
  final String currentSongId;
  final String currentSongCover;
  final String currentSongAudioUrl;
  final bool isOnline;
  final bool isListening;
  final DateTime lastSeen;

  Friend({
    required this.id,
    required this.name,
    required this.email,
    this.avatarInitials = '',
    this.currentSongTitle = '',
    this.currentSongArtist = '',
    this.currentSongId = '',
    this.currentSongCover = '',
    this.currentSongAudioUrl = '',
    this.isOnline = true,
    this.isListening = false,
    DateTime? lastSeen,
  }) : lastSeen = lastSeen ?? DateTime.now();

  String get initials {
    if (avatarInitials.isNotEmpty) return avatarInitials;
    if (name.isNotEmpty) {
      final parts = name.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name[0].toUpperCase();
    }
    if (email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    return '?';
  }

  Friend copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarInitials,
    String? currentSongTitle,
    String? currentSongArtist,
    String? currentSongId,
    String? currentSongCover,
    String? currentSongAudioUrl,
    bool? isOnline,
    bool? isListening,
    DateTime? lastSeen,
  }) {
    return Friend(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarInitials: avatarInitials ?? this.avatarInitials,
      currentSongTitle: currentSongTitle ?? this.currentSongTitle,
      currentSongArtist: currentSongArtist ?? this.currentSongArtist,
      currentSongId: currentSongId ?? this.currentSongId,
      currentSongCover: currentSongCover ?? this.currentSongCover,
      currentSongAudioUrl: currentSongAudioUrl ?? this.currentSongAudioUrl,
      isOnline: isOnline ?? this.isOnline,
      isListening: isListening ?? this.isListening,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarInitials': avatarInitials,
      'currentSongTitle': currentSongTitle,
      'currentSongArtist': currentSongArtist,
      'currentSongId': currentSongId,
      'currentSongCover': currentSongCover,
      'currentSongAudioUrl': currentSongAudioUrl,
      'isOnline': isOnline,
      'isListening': isListening,
      'lastSeen': lastSeen.toIso8601String(),
    };
  }

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'] as String? ?? 'f_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Friend',
      email: json['email'] as String? ?? '',
      avatarInitials: json['avatarInitials'] as String? ?? '',
      currentSongTitle: json['currentSongTitle'] as String? ?? '',
      currentSongArtist: json['currentSongArtist'] as String? ?? '',
      currentSongId: json['currentSongId'] as String? ?? '',
      currentSongCover: json['currentSongCover'] as String? ?? '',
      currentSongAudioUrl: json['currentSongAudioUrl'] as String? ?? '',
      isOnline: json['isOnline'] as bool? ?? true,
      isListening: json['isListening'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
