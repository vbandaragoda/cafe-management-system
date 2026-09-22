enum UserRole { customer, admin }

UserRole userRoleFromString(String? raw) {
  switch ((raw ?? '').toUpperCase()) {
    case 'ADMIN':
      return UserRole.admin;
    default:
      return UserRole.customer;
  }
}

class AppUser {
  final int id;
  final String name;
  final String email;
  final UserRole role;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  bool get isAdmin => role == UserRole.admin;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: userRoleFromString(json['role'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role == UserRole.admin ? 'ADMIN' : 'CUSTOMER',
      };
}
