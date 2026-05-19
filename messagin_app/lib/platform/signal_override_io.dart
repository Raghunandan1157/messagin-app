import 'dart:convert';
import 'dart:io';

class SignalOverride {
  final String? wss;
  final String? https;

  const SignalOverride({this.wss, this.https});
}

Future<SignalOverride?> readSignalOverride() async {
  final home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  if (home == null) return null;

  final file = File('$home/.messagin-signal.json');
  if (!await file.exists()) return null;

  final decoded = jsonDecode(await file.readAsString());
  if (decoded is! Map) return null;

  return SignalOverride(
    wss: decoded['wss'] as String?,
    https: decoded['https'] as String?,
  );
}
