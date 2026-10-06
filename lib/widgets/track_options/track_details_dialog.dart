import 'package:flutter/material.dart';
import '../../models/song.dart';

/// Modal bottom sheet displaying detailed metadata for a song.
void showTrackDetailsDialog(BuildContext context, Song song) {
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
