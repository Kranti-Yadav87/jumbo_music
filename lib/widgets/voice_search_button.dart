import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../services/database_service.dart';

/// Mic button that turns spoken words into a search query.
/// [onWords] fires with live partial text and once more with `isFinal == true`.
class VoiceSearchButton extends StatefulWidget {
  final void Function(String words, bool isFinal) onWords;
  final ValueChanged<bool>? onListeningChanged;

  const VoiceSearchButton({
    super.key,
    required this.onWords,
    this.onListeningChanged,
  });

  @override
  State<VoiceSearchButton> createState() => _VoiceSearchButtonState();
}

class _VoiceSearchButtonState extends State<VoiceSearchButton>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _ready = false;
  bool _listening = false;
  bool _starting = false;

  static const _hindiSetting = 'voice_search_hindi';

  /// Hindi is the default so users can say song names in Hindi.
  bool get _hindi =>
      DatabaseService.instance.getSetting(_hindiSetting, true) == true;

  /// Web Speech API expects BCP-47 tags (hi-IN); Android/iOS use hi_IN.
  String get _localeId {
    final tag = _hindi ? 'hi_IN' : 'en_IN';
    return kIsWeb ? tag.replaceAll('_', '-') : tag;
  }

  Future<void> _toggleLanguage() async {
    if (_starting) return;

    if (_listening) {
      try {
        await _speech.cancel();
      } catch (_) {
        _ready = false;
      } finally {
        _setListening(false);
      }
    }

    await DatabaseService.instance.updateSetting(_hindiSetting, !_hindi);
    if (!mounted) return;
    setState(() {});
    _toast(
      _hindi
          ? 'Voice search: Hindi (हिंदी) — bolkar gaana dhoondhein'
          : 'Voice search: English',
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    if (_listening) _speech.cancel();
    super.dispose();
  }

  void _setListening(bool value) {
    if (!mounted || _listening == value) return;
    setState(() => _listening = value);
    value ? _pulse.repeat(reverse: true) : _pulse.stop();
    widget.onListeningChanged?.call(value);
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _toggle() async {
    if (_starting) return;

    if (_listening) {
      _starting = true;
      try {
        await _speech.stop();
      } catch (_) {
        _ready = false;
        _toast('Could not stop voice search. Please try again.');
      } finally {
        _setListening(false);
        _starting = false;
      }
      return;
    }

    _starting = true;
    try {
      if (!_ready) {
        _ready = await _speech.initialize(
          onStatus: (status) {
            if (status == SpeechToText.doneStatus ||
                status == SpeechToText.notListeningStatus) {
              _setListening(false);
            }
          },
          onError: (error) {
            _ready = false;
            _setListening(false);
            _toast(
              error.permanent
                  ? 'Microphone access is needed for voice search.'
                  : "Didn't catch that. Tap the mic and try again.",
            );
          },
        );
      }

      if (!_ready) {
        _toast('Voice search is not available on this device or browser.');
        return;
      }

      HapticFeedback.selectionClick();
      _setListening(true);

      await _speech.listen(
        onResult: (result) {
          final words = result.recognizedWords.trim();
          if (words.isNotEmpty) widget.onWords(words, result.finalResult);
          if (result.finalResult) _setListening(false);
        },
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.search,
          partialResults: true,
          cancelOnError: true,
          listenFor: const Duration(seconds: 12),
          pauseFor: const Duration(seconds: 3),
          localeId: _localeId,
        ),
      );
    } catch (_) {
      _ready = false;
      _setListening(false);
      _toast(
        'Voice search could not start. Check microphone access and try again.',
      );
    } finally {
      _starting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: _hindi
              ? 'Voice language Hindi, tap for English'
              : 'Voice language English, tap for Hindi',
          child: InkWell(
            key: const ValueKey('voice-language-toggle'),
            borderRadius: BorderRadius.circular(10),
            onTap: _toggleLanguage,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                _hindi ? 'हि' : 'EN',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        _micButton(),
      ],
    );
  }

  Widget _micButton() {
    return Semantics(
      button: true,
      label: _listening ? 'Stop voice search' : 'Search by voice',
      child: IconButton(
        key: const ValueKey('voice-search-button'),
        tooltip: _listening ? 'Stop listening' : 'Search by voice',
        onPressed: _starting ? null : _toggle,
        icon: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            return Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _listening
                    ? const Color(0xFFFF0000)
                    : Colors.white.withValues(alpha: 0.08),
                boxShadow: _listening
                    ? [
                        BoxShadow(
                          color: const Color(
                            0xFFFF0000,
                          ).withValues(alpha: 0.25 + 0.35 * _pulse.value),
                          blurRadius: 6 + 10 * _pulse.value,
                          spreadRadius: 1 + 3 * _pulse.value,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: Colors.white,
                size: 19,
              ),
            );
          },
        ),
      ),
    );
  }
}
