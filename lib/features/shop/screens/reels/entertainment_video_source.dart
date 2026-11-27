import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class EntertainmentVideoSource {
  static const categories = {
    'animals': 'Thú cưng', 'travel': 'Du lịch', 'nature': 'Thiên nhiên',
    'sports': 'Thể thao', 'city': 'Nhịp sống', 'animation': 'Hoạt hình',
  };

  /// The server caches each fixed collection for 24 hours; no API key in the app.
  static Future<List<Map<String, dynamic>>> load() async {
    final pages = await Future.wait([
      for (final category in categories.keys)
      for (var page = 1; page <= (category == 'animation' ? 1 : 3); page++) _loadPage(category, page),
    ]);
    return arrange(pages.expand((page) => page).toList());
  }

  static List<Map<String, dynamic>> arrange(List<Map<String, dynamic>> videos, {Random? random}) {
    final seen = <String>{};
    final unique = videos.where((video) => seen.add(video['url'].toString())).toList();
    unique.shuffle(random);
    // Genuine sound first; shuffle within each group on every new feed load.
    return [
      ...unique.where((video) => video['audiblePreview'] == true),
      ...unique.where((video) => video['audiblePreview'] != true),
    ];
  }

  static Future<List<Map<String, dynamic>>> _loadPage(String category, int page) async {
      try {
        final response = await http.get(Uri.https(
          'velora-video-api.velora-cloud-push.workers.dev', '/collections/$category',
          {'page': '$page'},
        ), headers: {'User-Agent': 'VELORA/1.0'}).timeout(const Duration(seconds: 20));
        if (response.statusCode != 200) return <Map<String, dynamic>>[];
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (data['videos'] as List).map((entry) => {
          ...Map<String, dynamic>.from(entry), 'category': category,
        }).toList();
      } catch (_) { return <Map<String, dynamic>>[]; }
  }
}
