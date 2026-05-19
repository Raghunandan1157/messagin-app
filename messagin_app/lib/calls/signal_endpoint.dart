import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../platform/signal_override.dart';

String? signalProxyBase() {
  final endpoint = (dotenv.env['API_ENDPOINT'] ?? '').trim();
  if (endpoint.isEmpty) {
    return kIsWeb ? _origin(Uri.base) : null;
  }

  final parsed = Uri.parse(endpoint);
  final absolute = parsed.hasScheme
      ? parsed
      : kIsWeb
      ? Uri.base.resolve(endpoint)
      : parsed;

  if (!absolute.hasScheme || absolute.host.isEmpty) return null;

  var path = absolute.path;
  if (path.endsWith('/api/sql')) {
    path = path.substring(0, path.length - '/api/sql'.length);
  } else if (path.endsWith('/api')) {
    path = path.substring(0, path.length - '/api'.length);
  }
  path = path.replaceFirst(RegExp(r'/$'), '');

  return '${_origin(absolute)}$path';
}

Future<String?> publishedSignalWss() async {
  final base = signalProxyBase();
  if (base == null || base.isEmpty) return null;

  final resp = await http
      .get(Uri.parse('$base/api/signal-url'))
      .timeout(const Duration(seconds: 4));
  if (resp.statusCode != 200) return null;

  final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
  final wss = decoded['wss'] as String?;
  return wss != null && wss.isNotEmpty ? wss : null;
}

String? configuredSignalWss() {
  final wss = dotenv.env['SIGNAL_WSS_URL'];
  return wss != null && wss.isNotEmpty ? wss : null;
}

Future<String?> localOverrideWss() async {
  if (kIsWeb) return null;
  try {
    final override = await readSignalOverride();
    return override?.wss;
  } catch (e) {
    debugPrint('signal override read failed: $e');
    return null;
  }
}

Future<String?> localOverrideHttpBase() async {
  if (kIsWeb) return null;
  try {
    final override = await readSignalOverride();
    if (override?.https != null && override!.https!.isNotEmpty) {
      return override.https;
    }
    final wss = override?.wss;
    if (wss != null && wss.isNotEmpty) return signalHttpBaseFromWss(wss);
  } catch (e) {
    debugPrint('signal override read failed: $e');
  }
  return null;
}

String signalHttpBaseFromWss(String url) {
  return url
      .replaceFirst(RegExp(r'^wss://'), 'https://')
      .replaceFirst(RegExp(r'^ws://'), 'http://');
}

String _origin(Uri uri) {
  final port = uri.hasPort ? ':${uri.port}' : '';
  return '${uri.scheme}://${uri.host}$port';
}
