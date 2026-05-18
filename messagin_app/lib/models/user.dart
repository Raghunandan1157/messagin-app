class AppUser {
  final String id;
  final String phone;
  final String name;
  final String? avatarUrl;
  final String? about;
  final DateTime? lastSeen;

  AppUser({
    required this.id,
    required this.phone,
    required this.name,
    this.avatarUrl,
    this.about,
    this.lastSeen,
  });

  factory AppUser.fromRow(Map<String, dynamic> row) => AppUser(
        id: row['id'].toString(),
        phone: row['phone'] as String,
        name: row['name'] as String,
        avatarUrl: row['avatar_url'] as String?,
        about: row['about'] as String?,
        lastSeen: row['last_seen'] as DateTime?,
      );

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}
