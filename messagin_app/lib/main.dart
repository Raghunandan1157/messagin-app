import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'calls/call_controller.dart';
import 'calls/signaling.dart';
import 'models/user.dart';
import 'screens/home_shell.dart';
import 'screens/incoming_call_screen.dart';
import 'screens/login_screen.dart';
import 'screens/welcome_splash.dart';
import 'state/app_state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MessaginApp());
}

class MessaginApp extends StatelessWidget {
  const MessaginApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        // CallController depends on the signed-in user; we wrap it in a
        // ProxyProvider so it (re)builds when AppState.me changes.
        ChangeNotifierProxyProvider<AppState, _CallStack>(
          create: (_) => _CallStack(),
          update: (_, state, prev) {
            prev ??= _CallStack();
            prev.syncToUser(state.me?.id);
            return prev;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Messagin app',
        debugShowCheckedModeBanner: false,
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        navigatorKey: _appNavigatorKey,
        home: ChangeNotifierProvider<CallController?>.value(
          value: null, // overridden in _Root via Selector below
          child: const _Root(),
        ),
      ),
    );
  }
}

final GlobalKey<NavigatorState> _appNavigatorKey = GlobalKey<NavigatorState>();

/// Holds the live signaling client + call controller. Rebuilt when `me`
/// changes (sign in / sign out).
class _CallStack extends ChangeNotifier {
  String? _userId;
  SignalingClient? signaling;
  CallController? controller;
  bool _routedRinging = false;

  void syncToUser(String? userId) {
    if (userId == _userId) return;
    _userId = userId;
    _tearDown();
    if (userId == null) {
      notifyListeners();
      return;
    }
    signaling = SignalingClient(userId);
    controller = CallController(signaling: signaling!, selfUserId: userId);
    controller!.addListener(_onControllerChange);
    // Fire-and-forget; reconnect logic lives inside the client.
    // ignore: unawaited_futures
    signaling!.connect();
    notifyListeners();
  }

  void _onControllerChange() {
    final c = controller;
    if (c == null) return;
    if (c.state == CallState.ringing && !_routedRinging) {
      _routedRinging = true;
      _routeToIncoming();
    } else if (c.state == CallState.idle || c.state == CallState.ended) {
      _routedRinging = false;
    }
  }

  void _routeToIncoming() {
    // Defer so the navigator is mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = _appNavigatorKey.currentState;
      if (nav == null) return;
      final ctx = _appNavigatorKey.currentContext;
      if (ctx == null) return;
      final state = ctx.read<AppState>();
      final fromId = controller?.incomingFromUserId ?? 'unknown';
      final caller = state.contacts.firstWhere(
        (u) => u.id == fromId,
        orElse: () => AppUser(
          id: fromId,
          phone: '',
          name: 'Unknown caller',
        ),
      );
      nav.push(MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider<CallController>.value(value: controller!),
          ],
          child: IncomingCallScreen(caller: caller),
        ),
      ));
    });
  }

  void _tearDown() {
    controller?.removeListener(_onControllerChange);
    controller?.dispose();
    controller = null;
    // ignore: unawaited_futures
    signaling?.close();
    signaling = null;
  }

  @override
  void dispose() {
    _tearDown();
    super.dispose();
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final stack = context.watch<_CallStack>();
    if (state.initializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (state.me == null) return const LoginScreen();
    if (state.justSignedIn) {
      return WelcomeSplash(onDone: () => context.read<AppState>().clearJustSignedIn());
    }
    // Inject the live CallController into the widget tree so HomeShell +
    // ChatPane can launch calls without reaching into _CallStack directly.
    final ctrl = stack.controller;
    if (ctrl == null) return const HomeShell();
    return ChangeNotifierProvider<CallController>.value(
      value: ctrl,
      child: const HomeShell(),
    );
  }
}
