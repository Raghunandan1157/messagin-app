class AppUser {
  final String id;
  final String phone;
  final String name;
  final String? avatarUrl;
  final String? about;
  final DateTime? lastSeen;
  final String? empId;
  final String? role;
  final String? location;

  AppUser({
    required this.id,
    required this.phone,
    required this.name,
    this.avatarUrl,
    this.about,
    this.lastSeen,
    this.empId,
    this.role,
    this.location,
  });

  factory AppUser.fromRow(Map<String, dynamic> row) => AppUser(
        id: row['id'].toString(),
        phone: row['phone'] as String,
        name: row['name'] as String,
        avatarUrl: row['avatar_url'] as String?,
        about: row['about'] as String?,
        lastSeen: row['last_seen'] as DateTime?,
        empId: row['emp_id'] as String?,
        role: row['role'] as String?,
        location: row['location'] as String?,
      );

  String get tagline {
    final bits = <String>[];
    if (role != null && role!.isNotEmpty) bits.add(role!);
    if (location != null && location!.isNotEmpty) bits.add(location!);
    if (bits.isEmpty) return about ?? phone;
    return bits.join(' · ');
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}
