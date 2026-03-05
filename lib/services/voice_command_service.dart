import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/match.dart';

/// Possible voice commands recognised by the service.
enum VoiceAction { scoreTeam1, scoreTeam2, undo, finish, restart }

class VoiceCommand {
  final VoiceAction action;
  final String? playerId; // resolved player ID (doubles)
  final String rawText;
  VoiceCommand(this.action, this.rawText, {this.playerId});
}

/// Self-contained service wrapping `speech_to_text` + `flutter_tts`.
///
/// - Continuous listening via auto-restart on silence timeout.
/// - Keyword-based command parsing with 5-second cooldown.
/// - Doubles player-ID resolution (name match → server → first player).
/// - TTS readback for score confirmation.
class VoiceCommandService {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final _commandController = StreamController<VoiceCommand>.broadcast();

  bool _isAvailable = false;
  bool _wantListening = false; // user intent: should we be listening?
  DateTime _lastActionTime = DateTime(2000);
  Timer? _partialDebounce; // debounce timer for non-final results

  /// Cooldown between accepted commands.
  static const _cooldown = Duration(seconds: 5);

  Stream<VoiceCommand> get commands => _commandController.stream;
  bool get isListening => _speech.isListening;
  bool get isAvailable => _isAvailable;

  /// The match context — must be kept up-to-date by the caller.
  Match? currentMatch;

  // ──────────── Lifecycle ────────────

  Future<bool> initialize() async {
    print('[Voice] Initializing speech_to_text...');
    _isAvailable = await _speech.initialize(
      onStatus: _onStatus,
      onError: (e) {
        print('[Voice] ERROR: $e');
        _restartIfNeeded();
      },
    );
    print('[Voice] Speech available: $_isAvailable');
    if (_isAvailable) {
      final locales = await _speech.locales();
      print('[Voice] Available locales: ${locales.map((l) => l.localeId).take(5).toList()}');
    }
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    return _isAvailable;
  }

  Future<void> startListening() async {
    print('[Voice] startListening called. available=$_isAvailable');
    if (!_isAvailable) return;
    _wantListening = true;
    await _listen();
  }

  Future<void> stopListening() async {
    _wantListening = false;
    _partialDebounce?.cancel();
    await _speech.stop();
  }

  void dispose() {
    _wantListening = false;
    _partialDebounce?.cancel();
    _speech.stop();
    _commandController.close();
  }

  // ──────────── Internal Listening Loop ────────────

  Future<void> _listen() async {
    if (!_wantListening || _speech.isListening) {
      print('[Voice] _listen skipped: want=$_wantListening isListening=${_speech.isListening}');
      return;
    }
    print('[Voice] Starting speech.listen()...');
    await _speech.listen(
      onResult: _onResult,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      listenOptions: SpeechListenOptions(
        cancelOnError: false,
        listenMode: ListenMode.dictation,
      ),
    );
    print('[Voice] speech.listen() called, isListening=${_speech.isListening}');
  }

  void _onStatus(String status) {
    print('[Voice] Status: $status');
    // Only handle restart — result processing is done via debounce timer.
    if (status == 'notListening' || status == 'done') {
      _restartIfNeeded();
    }
  }

  void _restartIfNeeded() {
    if (_wantListening) {
      print('[Voice] Scheduling restart...');
      // Brief delay to avoid hammering the speech engine.
      Future.delayed(const Duration(milliseconds: 300), _listen);
    }
  }

  // ──────────── Result Handling ────────────

  void _onResult(SpeechRecognitionResult result) {
    print('[Voice] onResult: final=${result.finalResult} words="${result.recognizedWords}"');
    final text = result.recognizedWords.toLowerCase().trim();
    if (text.isEmpty) return;

    if (result.finalResult) {
      // Got a real final result — cancel any pending debounce, process now.
      _partialDebounce?.cancel();
      _parseAndEmit(text);
    } else {
      // Non-final: start/reset a 1-second debounce timer.
      // If no final comes, this fires and processes the partial.
      _partialDebounce?.cancel();
      _partialDebounce = Timer(const Duration(seconds: 1), () {
        print('[Voice] Debounce fired for partial: "$text"');
        _parseAndEmit(text);
      });
    }
  }

  void _parseAndEmit(String text) {
    // Cooldown check.
    final timeSince = DateTime.now().difference(_lastActionTime);
    if (timeSince < _cooldown) {
      print('[Voice] Cooldown active (${timeSince.inMilliseconds}ms), ignoring: "$text"');
      return;
    }

    VoiceCommand? cmd;

    // Priority order: undo > finish > restart > score
    if (_contains(text, ['undo', 'go back', 'take back'])) {
      cmd = VoiceCommand(VoiceAction.undo, text);
    } else if (_contains(text, ['restart', 'rematch', 'new game'])) {
      cmd = VoiceCommand(VoiceAction.restart, text);
    } else if (_contains(text, ['finish', 'end', 'game over', 'done'])) {
      cmd = VoiceCommand(VoiceAction.finish, text);
    } else if (_contains(text, ['blue', 'team 1', 'team one', 'left'])) {
      final pid = _resolvePlayerId(1, text);
      cmd = VoiceCommand(VoiceAction.scoreTeam1, text, playerId: pid);
    } else if (_contains(text, ['red', 'team 2', 'team two', 'right'])) {
      final pid = _resolvePlayerId(2, text);
      cmd = VoiceCommand(VoiceAction.scoreTeam2, text, playerId: pid);
    }

    if (cmd != null) {
      print('[Voice] COMMAND: ${cmd.action} from "$text"');
      _lastActionTime = DateTime.now();
      _commandController.add(cmd);
    } else {
      print('[Voice] No command matched for: "$text"');
    }
  }

  bool _contains(String text, List<String> keywords) =>
      keywords.any((k) => text.contains(k));

  // ──────────── Doubles Player ID Resolution ────────────

  String? _resolvePlayerId(int team, String text) {
    final m = currentMatch;
    if (m == null) return null;

    final ids = team == 1 ? m.team1Ids : m.team2Ids;
    final names = team == 1 ? m.team1Names : m.team2Names;

    // Singles: trivial.
    if (ids.length == 1) return ids[0];

    // 1. Try to find player name in the utterance.
    // Strip team keywords first to avoid false matches.
    final cleaned = text
        .replaceAll('blue', '')
        .replaceAll('red', '')
        .replaceAll('team', '')
        .replaceAll('left', '')
        .replaceAll('right', '')
        .replaceAll('one', '')
        .replaceAll('two', '')
        .replaceAll('1', '')
        .replaceAll('2', '')
        .trim();

    for (int i = 0; i < names.length; i++) {
      if (cleaned.contains(names[i].toLowerCase())) {
        return ids[i];
      }
    }

    // 2. Fallback: server if this team is serving.
    if (m.servingTeam == team && m.servingPlayerId.isNotEmpty) {
      if (ids.contains(m.servingPlayerId)) {
        return m.servingPlayerId;
      }
    }

    // 3. Final fallback: first player.
    return ids[0];
  }

  // ──────────── TTS Readback ────────────

  Future<void> announce(String message) async {
    await _tts.speak(message);
  }
}
