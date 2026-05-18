import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../state/app_state.dart';
import '../widgets/avatar.dart';
import 'chat_screen.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  List<AppUser> _users = [];
  final Set<String> _selected = {};
  bool _loading = true;
  bool _groupMode = false;
  final _groupTitle = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = context.read<AppState>();
    final all = await state.repo.listUsers();
    setState(() {
      _users = all.where((u) => u.id != state.me!.id).toList();
      _loading = false;
    });
  }

  Future<void> _startDirect(AppUser other) async {
    final state = context.read<AppState>();
    final chat = await state.repo.createDirectChat(state.me!.id, other.id);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)));
  }

  Future<void> _startGroup() async {
    final title = _groupTitle.text.trim();
    if (title.isEmpty || _selected.isEmpty) return;
    final state = context.read<AppState>();
    final chat = await state.repo.createGroupChat(state.me!.id, title, _selected.toList());
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_groupMode ? 'New group' : 'Select contact'),
        actions: [
          IconButton(
            icon: Icon(_groupMode ? Icons.person : Icons.group),
            tooltip: _groupMode ? 'Direct chat' : 'New group',
            onPressed: () => setState(() {
              _groupMode = !_groupMode;
              _selected.clear();
            }),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              if (_groupMode)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: TextField(
                    controller: _groupTitle,
                    decoration: const InputDecoration(
                      labelText: 'Group name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (_, i) {
                    final u = _users[i];
                    final selected = _selected.contains(u.id);
                    return ListTile(
                      leading: LoopAvatar(initials: u.initials, size: 44),
                      title: Text(u.name),
                      subtitle: Text(u.about ?? u.phone, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: _groupMode
                          ? Checkbox(
                              value: selected,
                              onChanged: (v) => setState(() {
                                if (v == true) {
                                  _selected.add(u.id);
                                } else {
                                  _selected.remove(u.id);
                                }
                              }),
                            )
                          : null,
                      onTap: _groupMode
                          ? () => setState(() {
                                if (selected) {
                                  _selected.remove(u.id);
                                } else {
                                  _selected.add(u.id);
                                }
                              })
                          : () => _startDirect(u),
                    );
                  },
                ),
              ),
            ]),
      floatingActionButton: _groupMode
          ? FloatingActionButton.extended(
              onPressed: _startGroup,
              icon: const Icon(Icons.check),
              label: Text('Create (${_selected.length})'),
            )
          : null,
    );
  }
}
