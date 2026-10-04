import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _selectedRating = 5;
  String _selectedCategory = 'Sound Quality & Audio';
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _categories = const [
    {'label': 'Sound Quality & Audio', 'icon': Icons.graphic_eq_rounded},
    {'label': 'Bug / Issue Report', 'icon': Icons.bug_report_rounded},
    {'label': 'Feature Suggestion', 'icon': Icons.auto_awesome_rounded},
    {'label': 'Music Catalog', 'icon': Icons.library_music_rounded},
    {'label': 'General Feedback', 'icon': Icons.chat_bubble_outline_rounded},
  ];

  final Map<int, String> _ratingLabels = const {
    1: 'Needs Major Work 😞',
    2: 'Below Expectations 😐',
    3: 'Good Experience 🙂',
    4: 'Great & Smooth! 😃',
    5: 'Outstanding / Loved It! 🌟🔥',
  };

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final text = _feedbackController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please share a few words about your experience.'),
          backgroundColor: Colors.amber,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final db = DatabaseService.instance;
    final payload = {
      'rating': _selectedRating,
      'category': _selectedCategory,
      'message': text,
      'userId': db.userId,
      'userName': db.userName,
      'userEmail': db.userEmail,
      'isGuest': db.isGuest,
      'submittedAt': DateTime.now().toIso8601String(),
      'appVersion': '2.0.0',
    };

    // 1. Try to sync to Firestore if online
    try {
      await FirebaseFirestore.instance.collection('app_feedback').add({
        ...payload,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}

    // 2. Add in-app confirmation notification
    await db.addNotification(
      title: 'Feedback Received',
      message: 'Thank you for rating Jumbo Music $_selectedRating/5 stars. We appreciate your feedback!',
      type: 'system',
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
              SizedBox(width: 10),
              Text(
                'Feedback Sent!',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Thank you for helping us improve Jumbo Music! Your suggestions have been directly recorded.',
            style: TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5E3A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final db = DatabaseService.instance;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D14) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF14141E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'App Feedback & Rating',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Banner Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF5E3A), Color(0xFFFF2A54)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF5E3A).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.rate_review_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Opinion Matters',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.5,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Help us shape the future of high-fidelity music streaming.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 1. Star Rating Section
          Text(
            'HOW WOULD YOU RATE YOUR EXPERIENCE?',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161622) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final star = index + 1;
                    final isFilled = star <= _selectedRating;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedRating = star),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: AnimatedScale(
                          scale: isFilled ? 1.15 : 1.0,
                          duration: const Duration(milliseconds: 150),
                          child: Icon(
                            isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: isFilled ? const Color(0xFFFFB800) : Colors.white24,
                            size: 40,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 10),
                Text(
                  _ratingLabels[_selectedRating] ?? '',
                  style: const TextStyle(
                    color: Color(0xFFFFB800),
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 2. Category Selector Chips
          Text(
            'SELECT TOPIC / CATEGORY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              final isSelected = _selectedCategory == cat['label'];
              return ChoiceChip(
                avatar: Icon(
                  cat['icon'] as IconData,
                  size: 16,
                  color: isSelected ? Colors.white : const Color(0xFFFF5E3A),
                ),
                label: Text(
                  cat['label'] as String,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF0F172A)),
                  ),
                ),
                selected: isSelected,
                selectedColor: const Color(0xFFFF5E3A),
                backgroundColor: isDark ? const Color(0xFF161622) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFFFF5E3A)
                        : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                  ),
                ),
                onSelected: (_) => setState(() => _selectedCategory = cat['label'] as String),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // 3. Message Input
          Text(
            'TELL US MORE DETAILS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161622) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
              ),
            ),
            child: TextField(
              controller: _feedbackController,
              maxLines: 5,
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14),
              decoration: InputDecoration(
                hintText: 'What do you love? What needs improvement? Suggest any songs, features, or bugs...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  fontSize: 13,
                ),
                contentPadding: const EdgeInsets.all(16),
                border: InputBorder.none,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Submitter Profile Pill
          Row(
            children: [
              Icon(Icons.account_circle_outlined, size: 14, color: isDark ? Colors.white38 : Colors.grey),
              const SizedBox(width: 6),
              Text(
                'Submitting as: ${db.userName} (${db.userId})',
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? Colors.white38 : const Color(0xFF64748B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Submit Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5E3A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_rounded, size: 20),
            label: Text(
              _isSubmitting ? 'Sending...' : 'Submit Feedback',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            onPressed: _isSubmitting ? null : _submitFeedback,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}