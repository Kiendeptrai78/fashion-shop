import 'dart:math';
import 'package:fashion_business_app/features/shop/screens/reels/entertainment_video_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feed changes order across sessions, deduplicates and prioritizes native audio', () {
    final videos = [for (var i = 0; i < 30; i++)
      <String, dynamic>{'url': 'https://example.com/$i.mp4', 'hasAudio': true, 'audiblePreview': i < 10}];
    final a = EntertainmentVideoSource.arrange([...videos, videos.first], random: Random(1));
    final b = EntertainmentVideoSource.arrange(videos, random: Random(2));
    expect(a.length, 30);
    expect(a.take(10).every((video) => video['audiblePreview'] == true), isTrue);
    expect(a.map((video) => video['url']).toList(),
        isNot(equals(b.map((video) => video['url']).toList())));
    expect(videos.first['url'], 'https://example.com/0.mp4');
  });
}
