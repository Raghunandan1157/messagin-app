import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/avatar.dart';
import '../widgets/skeletons.dart';
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

  // Filter chips
  String? _filterRole;
  String? _filterLocation;

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
    if (state.contacts.isNotEmpty) {
      setState(() {
        _users = state.contacts;
        _loading = false;
      });
    }
    if (!state.contactsLoaded) {
      await state.preloadContacts();
      if (!mounted) return;
      setState(() {
        _users = state.contacts;
        _loading = false;
      });
    } else {
      // ignore: unawaited_futures
      state.preloadContacts().then((_) {
        if (!mounted) return;
        setState(() => _users = state.contacts);
      });
    }
  }

  List<AppUser> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _users.where((u) {
      if (_filterRole != null && u.role != _filterRole) return false;
      if (_filterLocation != null && u.location != _filterLocation) return false;
      if (q.isEmpty) return true;
      return u.name.toLowerCase().contains(q) ||
          u.phone.toLowerCase().contains(q) ||
          (u.role?.toLowerCase().contains(q) ?? false) ||
          (u.location?.toLowerCase().contains(q) ?? false) ||
          (u.empId?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  List<AppUser> get _teammates {
    final me = context.read<AppState>().me;
    if (me == null) return const [];
    if (me.role == null && me.location == null) return const [];
    return _users.where((u) {
      final sameRole = me.role != null && u.role == me.role;
      final sameLoc = me.location != null && u.location == me.location;
      return sameRole || sameLoc;
    }).take(8).toList();
  }

  Map<String, List<AppUser>> _bucketAlpha(List<AppUser> list) {
    final sorted = [...list]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final map = <String, List<AppUser>>{};
    for (final u in sorted) {
      final t = u.name.trim();
      final k = t.isEmpty ? '#' : t[0].toUpperCase();
      final key = RegExp(r'[A-Z]').hasMatch(k) ? k : '#';
      map.putIfAbsent(key, () => []).add(u);
    }
    return map;
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

  Future<void> _pickFilter({required bool role}) async {
    final all = role
        ? _users.map((u) => u.role).whereType<String>().toSet().toList()
        : _users.map((u) => u.location).whereType<String>().toSet().toList();
    all.sort();
    final current = role ? _filterRole : _filterLocation;
    final picked = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, scroll) => Column(children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              Text(role ? 'Filter by role' : 'Filter by location',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: WAColors.inkLight)),
              const Spacer(),
              if (current != null)
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Clear'),
                ),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              controller: scroll,
              itemCount: all.length,
              itemBuilder: (_, i) {
                final v = all[i];
                return ListTile(
                  leading: Icon(role ? Icons.badge_outlined : Icons.place_outlined, color: WAColors.brand),
                  title: Text(v),
                  trailing: v == current ? const Icon(Icons.check, color: WAColors.brand) : null,
                  onTap: () => Navigator.pop(context, v),
                );
              },
            ),
          ),
        ]),
      ),
    );
    setState(() {
      if (role) {
        _filterRole = picked;
      } else {
        _filterLocation = picked;
      }
    });
  }

  Widget _contactRow(AppUser u) {
    final selected = _selected.contains(u.id);
    return ListTile(
      leading: LoopAvatar(initials: u.initials, size: 44),
      title: Text(u.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: WAColors.inkLight)),
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
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final searching = _searchCtrl.text.isNotEmpty || _filterRole != null || _filterLocation != null;
    final teammates = searching ? const <AppUser>[] : _teammates;
    final buckets = _bucketAlpha(filtered);
    final letters = buckets.keys.toList()..sort();

    return Scaffold(
      backgroundColor: WAColors.sidebarLight,
      appBar: AppBar(
        backgroundColor: WAColors.brandDark,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 72,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_groupMode ? 'New group' : 'Select contact',
                style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w500)),
            Text('${filtered.length} of ${_users.length} contacts',
                style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w400)),
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
          ? ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 10,
              itemBuilder: (_, i) => const ContactTileSkeleton(),
            )
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
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
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
                        style: const TextStyle(fontSize: 14, color: WAColors.inkLight),
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
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _filterChip(
                      label: _filterRole ?? 'Role',
                      active: _filterRole != null,
                      onTap: () => _pickFilter(role: true),
                      onClear: _filterRole == null ? null : () => setState(() => _filterRole = null),
                    ),
                    _filterChip(
                      label: _filterLocation ?? 'Location',
                      active: _filterLocation != null,
                      onTap: () => _pickFilter(role: false),
                      onClear: _filterLocation == null ? null : () => setState(() => _filterLocation = null),
                    ),
                  ],
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
                child: CustomScrollView(
                  slivers: [
                    if (teammates.isNotEmpty) ...[
                      const _SectionHeader('FROM YOUR TEAM', icon: Icons.workspace_premium_outlined),
                      SliverList.builder(
                        itemCount: teammates.length,
                        itemBuilder: (_, i) => _contactRow(teammates[i]),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 8)),
                    ],
                    if (filtered.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('No contacts match your filters',
                                style: TextStyle(color: WAColors.mutedLight)),
                          ),
                        ),
                      )
                    else
                      ...letters.expand((letter) => [
                            _SectionHeader(letter),
                            SliverList.builder(
                              itemCount: buckets[letter]!.length,
                              itemBuilder: (_, i) => _contactRow(buckets[letter]![i]),
                            ),
                          ]),
                  ],
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

  Widget _filterChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFD9FDD3) : WAColors.panelLight,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              active ? Icons.check : Icons.filter_list,
              size: 16,
              color: active ? WAColors.brandDark : WAColors.mutedLight,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? WAColors.brandDark : WAColors.inkLight,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (active && onClear != null) ...[
              const SizedBox(width: 6),
              InkWell(
                onTap: onClear,
                child: const Icon(Icons.close, size: 14, color: WAColors.brandDark),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  final IconData? icon;
  const _SectionHeader(this.text, {this.icon});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        color: WAColors.sidebarLight,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
        child: Row(children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: WAColors.brand),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: WAColors.brand,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ]),
      ),
    );
  }
}
