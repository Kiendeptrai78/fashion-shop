import 'package:fashion_business_app/common/widgets/videos/video_seek_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

class _Video extends VideoPlayerController {
  _Video({bool playing = true}) : super.networkUrl(Uri.parse('https://example.com/test.mp4')) {
    value = VideoPlayerValue(duration: const Duration(minutes: 2),
      position: const Duration(seconds: 10), isInitialized: true, isPlaying: playing);
  }
  Duration? seeked;
  int plays = 0, pauses = 0;
  @override
  Future<void> pause() async { pauses++; value = value.copyWith(isPlaying: false); }
  @override
  Future<void> play() async { plays++; value = value.copyWith(isPlaying: true); }
  @override
  Future<void> seekTo(Duration position) async { seeked = position; value = value.copyWith(position: position); }
}

void main() {
  for (final compact in [false, true]) {
  for (final playing in [true, false]) {
    testWidgets('scrubbing seeks and preserves playing=$playing compact=$compact', (tester) async {
      final video = _Video(playing: playing);
      await tester.pumpWidget(MaterialApp(home: Scaffold(backgroundColor: Colors.black,
        body: VideoSeekBar(controller: video, compact: compact))));
      expect(find.text('0:10'), compact ? findsNothing : findsOneWidget);
      expect(find.text('2:00'), compact ? findsNothing : findsOneWidget);
      await tester.drag(find.byType(Slider), const Offset(130, 0));
      await tester.pumpAndSettle();
      expect(video.seeked, isNotNull);
      expect(video.seeked!.inSeconds, greaterThan(10));
      expect(video.pauses, 1);
      expect(video.plays, playing ? 1 : 0);
      expect(tester.takeException(), isNull);
    });
  }
  }
  testWidgets('scrubbing an inactive reel does not resume its audio', (tester) async {
    final video = _Video();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: VideoSeekBar(controller: video, isActive: false))));
    await tester.drag(find.byType(Slider), const Offset(130, 0));
    await tester.pumpAndSettle();
    expect(video.plays, 0);
  });
}
