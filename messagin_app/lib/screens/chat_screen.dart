import 'package:flutter/material.dart';
import '../models/chat.dart';
import 'chat_pane.dart';

class ChatScreen extends StatelessWidget {
  final Chat chat;
  const ChatScreen({super.key, required this.chat});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChatPane(
        chat: chat,
        onBack: () => Navigator.pop(context),
      ),
    );
  }
}
