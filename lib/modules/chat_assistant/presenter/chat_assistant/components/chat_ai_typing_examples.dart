import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Digita cada exemplo letra a letra, segura um instante, apaga como um
/// backspace e passa ao próximo — em loop, com cursor piscando.
class ChatAiTypingExamples extends StatefulWidget {
  const ChatAiTypingExamples({
    super.key,
    required this.examples,
    this.active = true,
    this.selected,
  });

  final List<String> examples;

  /// `false`: para a animação e mostra só [selected].
  final bool active;
  final String? selected;

  @override
  State<ChatAiTypingExamples> createState() => _ChatAiTypingExamplesState();
}

class _ChatAiTypingExamplesState extends State<ChatAiTypingExamples> {
  static const _typeDelay = Duration(milliseconds: 70);
  static const _eraseDelay = Duration(milliseconds: 35);
  static const _holdDelay = Duration(milliseconds: 1400);
  static const _pauseDelay = Duration(milliseconds: 400);

  Timer? _timer;
  int _index = 0;
  int _chars = 0;
  bool _erasing = false;
  bool _cursorOn = true;

  @override
  void initState() {
    super.initState();
    if (widget.examples.isNotEmpty) _schedule(_pauseDelay);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _schedule(Duration d) => _timer = Timer(d, _tick);

  void _tick() {
    if (!mounted || !widget.active) return;
    final text = widget.examples[_index];
    Duration next;
    setState(() {
      _cursorOn = !_cursorOn || _chars != text.length;
      if (!_erasing) {
        if (_chars < text.length) {
          _chars++;
          next = _typeDelay;
        } else {
          _erasing = true;
          next = _holdDelay;
        }
      } else if (_chars > 0) {
        _chars--;
        next = _eraseDelay;
      } else {
        _erasing = false;
        _index = (_index + 1) % widget.examples.length;
        next = _pauseDelay;
      }
      _next = next;
    });
    _schedule(_next);
  }

  Duration _next = _pauseDelay;

  @override
  void didUpdateWidget(ChatAiTypingExamples old) {
    super.didUpdateWidget(old);
    if (!widget.active) _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return Text(
        widget.selected ?? '',
        style: const TextStyle(
          color: whiteColor,
          fontSize: 15.5,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
      );
    }
    final text =
        widget.examples.isEmpty
            ? ''
            : widget.examples[_index].substring(0, _chars);
    // Largura cheia do balão: ele não encolhe/estica a cada letra.
    return SizedBox(
      width: double.infinity,
      child: Row(
      children: [
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: whiteColor,
              fontSize: 15.5,
              height: 1.35,
            ),
          ),
        ),
        Opacity(
          opacity: _cursorOn ? 1 : 0,
          child: const Text(
            '|',
            style: TextStyle(
              color: chatHighlightColor,
              fontSize: 17,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
      ],
    ),
    );
  }
}
