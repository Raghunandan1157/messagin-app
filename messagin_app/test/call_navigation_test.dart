import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:messagin_app/calls/call_controller.dart';
import 'package:messagin_app/calls/signaling.dart';
import 'package:messagin_app/models/user.dart';
import 'package:messagin_app/screens/incoming_call_screen.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('incoming call route closes when call returns to idle', (
    tester,
  ) async {
    final controller = CallController(
      signaling: SignalingClient('self-user'),
      selfUserId: 'self-user',
    );
    final caller = AppUser(
      id: 'caller-user',
      phone: '+10000000000',
      name: 'Caller',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        ChangeNotifierProvider<CallController>.value(
                          value: controller,
                          child: IncomingCallScreen(caller: caller),
                        ),
                  ),
                );
              },
              child: const Text('Open incoming call'),
            );
          },
        ),
      ),
    );

    controller.setIncoming(
      chatId: 'chat-1',
      callerUserId: caller.id,
      video: false,
    );
    await tester.tap(find.text('Open incoming call'));
    await tester.pumpAndSettle();

    expect(find.byType(IncomingCallScreen), findsOneWidget);

    await controller.reject();
    await tester.pumpAndSettle();

    expect(find.byType(IncomingCallScreen), findsNothing);

    controller.dispose();
  });
}
