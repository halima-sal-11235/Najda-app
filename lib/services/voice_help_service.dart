import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceHelpService {
  final SpeechToText _speech = SpeechToText();
  final List<String> _locales = [];
  int _localeIndex = 0;
  bool _active = false;
  bool _starting = false;

  void Function(String text)? _onText;
  void Function(String text)? _onHelp;

  static const _keywords = [
    'help', 'au secours', 'secours',
    'ساعدوني', 'ساعدني', 'النجدة', 'نجدة', 'الحقوني',
    'عاونوني', 'انقذوني', 'أنقذوني', 'سعفوني',
  ];

  static String _normalize(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[أإآ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه')
      .replaceAll(RegExp('[\u064B-\u0652]'), ''); // Arabic diacritics

  static final List<String> _normKeywords =
      _keywords.map(_normalize).toList();

  /// Returns false if speech recognition isn't available or permission refused
  Future<bool> init() async {
    final ok = await _speech.initialize(
      onStatus: _onStatus,
      onError: (e) => debugPrint('speech error: ${e.errorMsg}'),
    );
    if (!ok) return false;

    final ids = (await _speech.locales()).map((l) => l.localeId).toList();
    String? find(String prefix) {
      for (final id in ids) {
        if (id.toLowerCase().replaceAll('-', '_').startsWith(prefix)) return id;
      }
      return null;
    }

    _locales
      ..clear()
      ..addAll({find('ar_dz'), find('ar'), find('fr'), find('en')}
          .whereType<String>());
    debugPrint('Voice locales: $_locales');
    return true;
  }

  Future<void> start({
    required void Function(String text) onText,
    required void Function(String text) onHelp,
  }) async {
    _onText = onText;
    _onHelp = onHelp;
    _active = true;
    await _listenOnce();
  }

  Future<void> _listenOnce() async {
    if (!_active || _starting || _speech.isListening) return;
    _starting = true;
    try {
      final localeId =
          _locales.isEmpty ? null : _locales[_localeIndex++ % _locales.length];
      await _speech.listen(
        localeId: localeId,
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 4),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.dictation,
        ),
        onResult: (r) {
          final text = r.recognizedWords;
          if (text.isEmpty) return;
          _onText?.call(text);
          final t = _normalize(text);
          if (_normKeywords.any(t.contains)) _onHelp?.call(text);
        },
      );
    } finally {
      _starting = false;
    }
  }

  void _onStatus(String status) {
    // The recognizer stops by itself after silence: restart it
    if (_active && (status == 'done' || status == 'notListening')) {
      Future.delayed(const Duration(milliseconds: 400), _listenOnce);
    }
  }

  Future<void> stop() async {
    _active = false;
    await _speech.cancel();
  }
}