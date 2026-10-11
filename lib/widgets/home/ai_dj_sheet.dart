import 'package:flutter/material.dart';
import '../../services/gemini_ai_service.dart';
import '../../services/music_player_manager.dart';

class AiDjSheet extends StatefulWidget {
  final String? initialPrompt;

  const AiDjSheet({super.key, this.initialPrompt});

  static Future<void> show(BuildContext context, {String? initialPrompt}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AiDjSheet(initialPrompt: initialPrompt),
    );
  }

  @override
  State<AiDjSheet> createState() => _AiDjSheetState();
}

class _AiDjSheetState extends State<AiDjSheet> {
  late final TextEditingController _controller;
  bool _isLoading = false;
  String _statusText = '';

  static const List<Map<String, String>> _quickVibes = [
    {'emoji': '🌧️', 'label': 'Monsoon Chai', 'prompt': 'Rainy monsoon acoustic emotional bollywood vibes'},
    {'emoji': '🔥', 'label': 'Gym Beast Mode', 'prompt': 'High energy gym workout motivational pump trap rap'},
    {'emoji': '🌙', 'label': 'Late Night Drive', 'prompt': 'Late night cruising lo-fi chill hindi melodies'},
    {'emoji': '💔', 'label': 'Heartbreak Pain', 'prompt': 'Deep sad heartbreak acoustic soulful hindi songs'},
    {'emoji': '✨', 'label': '90s Golden Era', 'prompt': 'Best nostalgic 90s and 2000s bollywood evergreen hits'},
    {'emoji': '⚡', 'label': 'Party Anthem', 'prompt': 'High octane club party dance bangers upbeat'},
    {'emoji': '☕', 'label': 'Study & Focus', 'prompt': 'Relaxing calm acoustic instrumental focus study music'},
    {'emoji': '🎸', 'label': 'Indie Gems', 'prompt': 'Underrated modern indian indie acoustic folk pop'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPrompt ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _generateAndPlay(String prompt) async {
    final cleanPrompt = prompt.trim();
    if (cleanPrompt.isEmpty) return;

    setState(() {
      _isLoading = true;
      _statusText = 'Gemini AI is curating your mix...';
    });

    try {
      final songs = await GeminiAiService.instance.generatePlayableSongs(
        prompt: cleanPrompt,
        count: 10,
      );

      if (!mounted) return;

      if (songs.isNotEmpty) {
        setState(() {
          _statusText = 'Launching playback for ${songs.length} tracks...';
        });

        await MusicPlayerManager().playPlaylist(songs, initialIndex: 0);

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF1E1B4B),
              content: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFFA855F7), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'AI Mix launched: "$cleanPrompt" (${songs.length} tracks)',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
          _statusText = 'No tracks matched. Try a slightly different vibe.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusText = 'Error generating mix. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: bottomInset + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF13131A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0xFF312E81), width: 1.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jumbo AI Smart DJ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Powered by Gemini • Instant custom vibe mix',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Prompt TextField
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E28),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: Color(0xFFA855F7), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_isLoading,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Type any vibe (e.g. Arijit rain acoustic, Gym pump...)',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        _generateAndPlay(val);
                      }
                    },
                  ),
                ),
                if (_controller.text.isNotEmpty && !_isLoading)
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                    onPressed: () => setState(() => _controller.clear()),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick Vibe Chips
          const Text(
            'Quick Vibe Presets',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickVibes.map((item) {
              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _isLoading
                    ? null
                    : () {
                        _controller.text = item['label']!;
                        _generateAndPlay(item['prompt']!);
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E28),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item['emoji']!, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 6),
                      Text(
                        item['label']!,
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
            }).toList(),
          ),
          const SizedBox(height: 22),

          // Loading status or Action button
          if (_isLoading)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1B4B).withOpacity(0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFFA855F7),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _statusText.isNotEmpty ? _statusText : 'Crafting your personalized mix...',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    final p = _controller.text.trim();
                    _generateAndPlay(p.isNotEmpty ? p : 'Top trending romantic & upbeat hits');
                  },
                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                  label: const Text(
                    'Generate & Play AI Mix',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
