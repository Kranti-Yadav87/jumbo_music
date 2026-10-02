import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/song.dart';
import '../services/music_player_manager.dart';
import '../services/download_service.dart';

class TrackOptionsSheet extends StatefulWidget {
  final Song song;

  const TrackOptionsSheet({super.key, required this.song});

  static Future<void> show(BuildContext context, Song song) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TrackOptionsSheet(song: song),
    );
  }

  @override
  State<TrackOptionsSheet> createState() => _TrackOptionsSheetState();
}

class _TrackOptionsSheetState extends State<TrackOptionsSheet> {
  void _showDetailsDialog(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141416),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Track Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Title', song.title),
                _buildDetailRow('Artist', song.artist),
                _buildDetailRow('Album', song.album),
                _buildDetailRow('Genre', song.genre),
                _buildDetailRow('Year', song.releaseYear),
                _buildDetailRow('Quality', song.quality),
                _buildDetailRow('Duration', song.formattedDuration),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showEqualizerPicker(BuildContext context, MusicPlayerManager manager) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141416),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Equalizer Presets',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: manager.soundPresets.map((preset) {
                    final isSel = manager.soundPreset == preset;
                    return ChoiceChip(
                      label: Text(preset),
                      selected: isSel,
                      selectedColor: const Color(0xFFE5A5A5),
                      backgroundColor: Colors.white.withOpacity(0.08),
                      labelStyle: TextStyle(
                        color: isSel ? Colors.black : Colors.white70,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) {
                        manager.setSoundPreset(preset);
                        Navigator.pop(ctx);
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTempoDialog(BuildContext context, MusicPlayerManager manager) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141416),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final speeds = [0.75, 1.0, 1.25, 1.5, 2.0];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tempo and Pitch',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: speeds.map((speed) {
                    final isSelected = (manager.playbackSpeed == speed);
                    return ChoiceChip(
                      label: Text('x${speed.toStringAsFixed(2)}'),
                      selected: isSelected,
                      selectedColor: const Color(0xFFE5A5A5),
                      backgroundColor: Colors.white.withOpacity(0.08),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : Colors.white70,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      onSelected: (_) {
                        manager.setPlaybackSpeed(speed);
                        Navigator.pop(ctx);
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = MusicPlayerManager();
    final downloadService = DownloadService();
    final song = widget.song;

    return AnimatedBuilder(
      animation: Listenable.merge([manager, downloadService]),
      builder: (context, _) {
        final isDownloaded = downloadService.isDownloaded(song.id);
        final isDownloading = downloadService.isDownloading(song.id);
        final fileSize = downloadService.getFileSize(song.id) ?? '10.2 MB';
        final volumePercent = (manager.volume * 100).round();

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0D0D0E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Drag Handle
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 1. Header Card (Now Playing, Artwork, Title, Artist)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            song.coverUrl,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 52,
                              height: 52,
                              color: const Color(0xFF2C2C2E),
                              child: const Icon(
                                Icons.music_note,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Now Playing',
                                style: TextStyle(
                                  color: Color(0xFF8E8E93),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF8E8E93),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 2. Volume Card
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Volume',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '$volumePercent%',
                              style: const TextStyle(
                                color: Color(0xFF8E8E93),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 12,
                                  trackShape:
                                      const RoundedRectSliderTrackShape(),
                                  thumbShape: SliderComponentShape.noThumb,
                                  overlayShape: SliderComponentShape.noOverlay,
                                  activeTrackColor: const Color(0xFFE5A5A5),
                                  inactiveTrackColor: const Color(0xFF2C2C2E),
                                ),
                                child: Slider(
                                  value: manager.volume,
                                  min: 0.0,
                                  max: 1.0,
                                  onChanged: (val) => manager.setVolume(val),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.volume_up_rounded,
                              color: Color(0xFF8E8E93),
                              size: 22,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 3. Action Grid (Start radio, Add to playlist, Copy link)
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.sensors_rounded,
                          label: 'Start radio',
                          onTap: () {
                            Navigator.pop(context);
                            manager.playSong(song);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Started radio based on "${song.title}"',
                                ),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.playlist_add_rounded,
                          label: 'Add to playlist',
                          onTap: () {
                            Navigator.pop(context);
                            _showAddToPlaylistSheet(context, manager, song);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.link_rounded,
                          label: 'Copy link',
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(text: song.audioUrl),
                            );
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Song link copied to clipboard!'),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // 4. Flame Tag: Jumbo Mus
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 110,
                      decoration: BoxDecoration(
                        color: const Color(0xFF242426),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_fire_department_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Jumbo Mus',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 5. View Artist Button
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.person_pin_circle_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                      title: const Text(
                        'View artist',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Artist: ${song.artist}'),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 6. Prominent 320kbps Download Button (Requested explicitly by user)
                  Container(
                    decoration: BoxDecoration(
                      color: isDownloaded
                          ? const Color(0xFF0F2E22)
                          : const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(20),
                      border: isDownloaded
                          ? Border.all(
                              color: const Color(0xFF10B981).withOpacity(0.5),
                            )
                          : null,
                    ),
                    child: ListTile(
                      leading: isDownloading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFE5A5A5),
                                ),
                              ),
                            )
                          : Icon(
                              isDownloaded
                                  ? Icons.download_done_rounded
                                  : Icons.download_rounded,
                              color: isDownloaded
                                  ? const Color(0xFF10B981)
                                  : Colors.white,
                              size: 24,
                            ),
                      title: Text(
                        isDownloaded
                            ? 'Downloaded ($fileSize)'
                            : isDownloading
                            ? 'Downloading (320 kbps)...'
                            : 'Download',
                        style: TextStyle(
                          color: isDownloaded
                              ? const Color(0xFF10B981)
                              : Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        isDownloaded
                            ? 'Saved to Library > Downloaded • Offline Ready'
                            : 'Save high-quality 320 kbps MP3 to device',
                        style: TextStyle(
                          color: isDownloaded
                              ? Colors.white70
                              : const Color(0xFF8E8E93),
                          fontSize: 11,
                        ),
                      ),
                      trailing: isDownloaded
                          ? IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              onPressed: () {
                                downloadService.removeDownload(song.id);
                              },
                            )
                          : null,
                      onTap: () {
                        if (!isDownloading) {
                          downloadService.downloadSong(song, context: context);
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 7. Grouped Card (Details, Equalizer, Tempo and Pitch)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.info_outline_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          title: const Text(
                            'Details',
                            style: TextStyle(color: Colors.white, fontSize: 15),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _showDetailsDialog(context, song);
                          },
                        ),
                        const Divider(height: 1, color: Color(0xFF2C2C2E)),
                        ListTile(
                          leading: const Icon(
                            Icons.equalizer_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          title: const Text(
                            'Equalizer',
                            style: TextStyle(color: Colors.white, fontSize: 15),
                          ),
                          subtitle: Text(
                            manager.equalizerSupported
                                ? manager.soundPreset
                                : '${manager.soundPreset} • Android app only',
                            style: const TextStyle(
                              color: Color(0xFF8E8E93),
                              fontSize: 12,
                            ),
                          ),
                          onTap: () {
                            _showEqualizerPicker(context, manager);
                          },
                        ),
                        const Divider(height: 1, color: Color(0xFF2C2C2E)),
                        ListTile(
                          leading: const Icon(
                            Icons.speed_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          title: const Text(
                            'Tempo and Pitch',
                            style: TextStyle(color: Colors.white, fontSize: 15),
                          ),
                          subtitle: Text(
                            'x${manager.playbackSpeed.toStringAsFixed(2)} • x1.00',
                            style: const TextStyle(
                              color: Color(0xFF8E8E93),
                              fontSize: 12,
                            ),
                          ),
                          onTap: () {
                            _showTempoDialog(context, manager);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF242426),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToPlaylistSheet(
    BuildContext context,
    MusicPlayerManager manager,
    Song song,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141416),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add to Playlist',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showCreatePlaylistDialog(
                          context,
                          manager,
                          addSong: song,
                        );
                      },
                      icon: const Icon(
                        Icons.add_rounded,
                        size: 18,
                        color: Color(0xFFE5A5A5),
                      ),
                      label: const Text(
                        'New',
                        style: TextStyle(
                          color: Color(0xFFE5A5A5),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (manager.playlists.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'No playlists yet. Tap "New" above to create one!',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: manager.playlists.length,
                      itemBuilder: (_, index) {
                        final pl = manager.playlists[index];
                        final alreadyIn = pl.songIds.contains(song.id);
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              pl.coverUrl,
                              width: 42,
                              height: 42,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 42,
                                height: 42,
                                color: const Color(0xFF2C2C2E),
                                child: const Icon(
                                  Icons.queue_music,
                                  color: Colors.white54,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            pl.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            alreadyIn
                                ? 'Already added • ${pl.songIds.length} songs'
                                : '${pl.songIds.length} songs',
                            style: TextStyle(
                              color: alreadyIn
                                  ? const Color(0xFF10B981)
                                  : Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          trailing: Icon(
                            alreadyIn
                                ? Icons.check_circle_rounded
                                : Icons.add_circle_outline_rounded,
                            color: alreadyIn
                                ? const Color(0xFF10B981)
                                : Colors.white54,
                            size: 22,
                          ),
                          onTap: () {
                            if (!alreadyIn) {
                              manager.addSongToPlaylist(pl.id, song.id);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Added "${song.title}" to ${pl.title}',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } else {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '"${song.title}" is already in ${pl.title}',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreatePlaylistDialog(
    BuildContext context,
    MusicPlayerManager manager, {
    Song? addSong,
  }) {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (dCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'New Playlist',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: titleController,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Playlist Name',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE5A5A5),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isNotEmpty) {
                  final newPl = await manager.createPlaylist(
                    title,
                    description: 'Custom Collection',
                  );
                  if (addSong != null) {
                    await manager.addSongToPlaylist(newPl.id, addSong.id);
                  }
                  if (context.mounted) {
                    Navigator.pop(dCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Created playlist "$title"${addSong != null ? ' and added "${addSong.title}"' : ''}',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Create',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
