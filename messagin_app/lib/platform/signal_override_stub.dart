class SignalOverride {
  final String? wss;
  final String? https;

  const SignalOverride({this.wss, this.https});
}

Future<SignalOverride?> readSignalOverride() async => null;
