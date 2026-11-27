import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoSeekBar extends StatefulWidget {
  const VideoSeekBar({super.key, required this.controller, this.isActive = true,
    this.compact = false});
  final VideoPlayerController controller;
  final bool isActive;
  final bool compact;
  @override
  State<VideoSeekBar> createState() => _VideoSeekBarState();
}

class _VideoSeekBarState extends State<VideoSeekBar> {
  double? _dragPosition;
  bool _resume = false;
  String _time(double milliseconds) {
    final seconds = milliseconds ~/ 1000;
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<VideoPlayerValue>(
    valueListenable: widget.controller,
    builder: (context, value, _) {
      final duration = value.duration.inMilliseconds.toDouble();
      final position = (_dragPosition ?? value.position.inMilliseconds.toDouble()).clamp(0.0, duration);
      final showTimes = !widget.compact;
      return SizedBox(height: widget.compact ? 28 : 48, child: Row(children: [
        if (showTimes) Text(_time(position), style: const TextStyle(color: Colors.white, fontSize: 11)),
        Expanded(child: SliderTheme(data: SliderTheme.of(context).copyWith(
          trackHeight: widget.compact ? 2 : 3,
          thumbShape: RoundSliderThumbShape(enabledThumbRadius:
            widget.compact && _dragPosition == null ? 2 : 6),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
          activeTrackColor: widget.compact ? Colors.white70 : const Color(0xFFDDEABB),
          inactiveTrackColor: Colors.white30,
          showValueIndicator: widget.compact ? ShowValueIndicator.always
              : SliderTheme.of(context).showValueIndicator,
          thumbColor: Colors.white), child: Slider(
          value: position, min: 0, max: duration > 0 ? duration : 1,
          label: widget.compact ? _time(position) : null,
          semanticFormatterCallback: _time,
          onChangeStart: duration <= 0 ? null : (next) {
            _resume = widget.controller.value.isPlaying;
            widget.controller.pause();
            setState(() => _dragPosition = next);
          },
          onChanged: duration <= 0 ? null : (next) => setState(() => _dragPosition = next),
          onChangeEnd: duration <= 0 ? null : (next) async {
            await widget.controller.seekTo(Duration(milliseconds: next.round()));
            if (!mounted) return;
            setState(() => _dragPosition = null);
            if (_resume && widget.isActive) await widget.controller.play();
          },
        ))),
        if (showTimes) Text(_time(duration), style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ]));
    });
}
