import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:web/web.dart' as web;

void configureWebUrlStrategy() {
  usePathUrlStrategy();
}

void syncBrowserPath(String path) {
  try {
    final normalized = path.startsWith('/') ? path : '/$path';
    if (web.window.location.pathname != normalized) {
      web.window.history.replaceState(null, '', normalized);
    }
  } catch (_) {}
}

String initialBrowserPath() {
  try {
    return web.window.location.pathname;
  } catch (_) {
    return '/';
  }
}
