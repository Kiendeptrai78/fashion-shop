import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

Future<Map<String, dynamic>?> pickStockVideo(BuildContext context) =>
    showDialog<Map<String, dynamic>>(context: context, builder: (_) => const _StockVideoPicker());

class _StockVideoPicker extends StatefulWidget {
  const _StockVideoPicker();
  @override
  State<_StockVideoPicker> createState() => _StockVideoPickerState();
}

class _StockVideoPickerState extends State<_StockVideoPicker> {
  final _search = TextEditingController(text: 'sneakers');
  List<Map<String, dynamic>> _videos = [];
  bool _loading = false, _more = false;
  int _page = 1;
  String? _error;
  String _query = 'sneakers';
  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _load({int page = 1, bool search = false}) async {
    if (_loading) return;
    if (search) _query = _search.text.trim();
    setState(() { _loading = true; _error = null; });
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) throw StateError('Vui lòng đăng nhập tài khoản Admin.');
      final response = await http.get(Uri.https('velora-video-api.velora-cloud-push.workers.dev',
        '/videos', {'q': _query, 'page': '$page'}), headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 25));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) throw StateError(data['error'] ?? 'Không tải được kho video.');
      if (mounted) {
        setState(() {
          _videos = (data['videos'] as List).map((entry) => Map<String, dynamic>.from(entry)).toList();
          _page = page; _more = data['hasMore'] == true;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error is StateError ? error.message.toString()
            : 'Không kết nối được kho video. Vui lòng thử lại.');
      }
    } finally { if (mounted) { setState(() => _loading = false); } }
  }

  @override
  Widget build(BuildContext context) => Dialog(child: SizedBox(width: 780, height: 680,
    child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
      Row(children: [const Expanded(child: Text('Kho video Pixabay',
        style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700))),
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))]),
      const Text('Video cảm hứng từ tác giả thật. Sản phẩm được gắn là gợi ý mua sắm, không phải lời chứng thực của tác giả.'),
      const SizedBox(height: 16),
      Row(children: [Expanded(child: TextField(controller: _search,
        decoration: const InputDecoration(hintText: 'Tìm: sneakers, running, basketball…'),
        onSubmitted: (_) => _load(search: true))), const SizedBox(width: 10),
        FilledButton(onPressed: _loading ? null : () => _load(search: true), child: const Text('Tìm video'))]),
      const SizedBox(height: 16),
      if (_error != null) Padding(padding: const EdgeInsets.all(12), child: Text(_error!,
        style: TextStyle(color: Theme.of(context).colorScheme.error))),
      Expanded(child: _loading ? const Center(child: CircularProgressIndicator())
        : _videos.isEmpty ? const Center(child: Text('Chưa có video. Thử từ khóa khác hoặc bấm tìm lại.'))
        : ListView.separated(itemCount: _videos.length, separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final video = _videos[index];
            return ListTile(contentPadding: EdgeInsets.zero,
              leading: SizedBox(width: 96, child: (video['thumbnail'] as String? ?? '').isEmpty
                ? const Icon(Icons.movie_outlined) : Image.network(video['thumbnail'], fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.movie_outlined))),
              title: Text('${video['author']} · Pixabay'),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${video['duration']}s · ${video['tags']}'),
                TextButton(onPressed: () => launchUrl(Uri.parse(video['sourceUrl'])),
                  child: const Text('Xem video & nguồn ↗')),
              ]),
              trailing: FilledButton(onPressed: () => Navigator.pop(context, video),
                child: const Text('Gắn video')));
          })),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        TextButton(onPressed: _loading || _page <= 1 ? null : () => _load(page: _page - 1),
          child: const Text('Trang trước')),
        Text('Trang $_page · 10 video / trang'),
        TextButton(onPressed: _loading || !_more ? null : () => _load(page: _page + 1),
          child: const Text('Trang sau')),
      ]),
    ]))));
}
