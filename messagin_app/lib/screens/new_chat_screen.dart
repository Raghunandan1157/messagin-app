import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../state/app_state.dart';
import '../theme.dart';
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
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _groupTitle.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final state = context.read<AppState>();
    final all = await state.repo.listUsers();
    if (!mounted) return;
    setState(() {
      _users = all.where((u) => u.id != state.me!.id).toList();
      _loading = false;
    });
  }

  List<AppUser> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _users;
    return _users.where((u) {
      return u.name.toLowerCase().contains(q) ||
          u.phone.toLowerCase().contains(q) ||
          (u.role?.toLowerCase().contains(q) ?? false) ||
          (u.location?.toLowerCase().contains(q) ?? false) ||
          (u.empId?.toLowerCase().contains(q) ?? false);
    }).toList();
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
      backgroundColor: WAColors.sidebarLight,
      appBar: AppBar(
        backgroundColor: WAColors.brandDark,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_groupMode ? 'New group' : 'Select contact',
                style: const TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.w500)),
            Text('${_filtered.length} contacts',
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_groupMode ? Icons.person : Icons.group_add, color: Colors.white),
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
                      labelText: 'Group subject',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: WAColors.panelLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    const SizedBox(width: 14),
                    const Icon(Icons.search, size: 18, color: WAColors.mutedLight),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Search name, role, location, or emp_id',
                          hintStyle: TextStyle(color: WAColors.mutedLight, fontSize: 14),
                          border: InputBorder.none,
                          isCollapsed: true,
                        ),
                      ),
                    ),
                    if (_searchCtrl.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: WAColors.mutedLight),
                        onPressed: () => _searchCtrl.clear(),
                      ),
                  ]),
                ),
              ),
              if (_groupMode && _selected.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  child: SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _selected.map((id) {
                        final u = _users.firstWhere((x) => x.id == id);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Chip(
                            label: Text(u.name, style: const TextStyle(fontSize: 12)),
                            onDeleted: () => setState(() => _selected.remove(id)),
                            backgroundColor: WAColors.panelLight,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final u = _filtered[i];
                    final selected = _selected.contains(u.id);
                    return ListTile(
                      leading: LoopAvatar(initials: u.initials, size: 44),
                      title: Text(u.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                      subtitle: Text(
                        u.tagline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: WAColors.mutedLight),
                      ),
                      trailing: _groupMode
                          ? Checkbox(
                              value: selected,
                              activeColor: WAColors.brand,
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
              backgroundColor: WAColors.brand,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.check),
              label: Text('Create (${_selected.length})'),
            )
          : null,
    );
  }
}
