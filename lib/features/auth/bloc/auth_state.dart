part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => const [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final User user;
  final String token;
  const AuthAuthenticated(this.user, this.token);
  @override
  List<Object?> get props => [user, token];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  final Map<String, String?> fieldErrors;
  const AuthError(this.message, {this.fieldErrors = const {}});
  @override
  List<Object?> get props => [message, fieldErrors];
}

class AuthForgotPasswordSent extends AuthState {
  const AuthForgotPasswordSent();
}

class AuthResetPasswordSuccess extends AuthState {
  const AuthResetPasswordSuccess();
}

class AuthPasswordChangedSuccess extends AuthState {
  const AuthPasswordChangedSuccess();
}

class User extends Equatable {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? phoneVerifiedAt;
  final String? gender;
  final String? birthDate;
  final String? avatarUrl;
  final bool isActive;
  final String? emailVerifiedAt;
  final String? lastLoginAt;
  final List<String> roles;
  final String? primaryRole;
  final bool isAdmin;
  final bool isCustomer;
  final String? createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.phoneVerifiedAt,
    this.gender,
    this.birthDate,
    this.avatarUrl,
    required this.isActive,
    this.emailVerifiedAt,
    this.lastLoginAt,
    this.roles = const ['customer'],
    this.primaryRole,
    required this.isAdmin,
    required this.isCustomer,
    this.createdAt,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  factory User.fromJson(Map<String, dynamic> json) {
    final rawRoles = json['roles'];
    final roles = rawRoles is List
        ? rawRoles.map((e) => e.toString()).toList()
        : const ['customer'];
    return User(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      phone: json['phone'] as String?,
      phoneVerifiedAt: json['phone_verified_at'] as String?,
      gender: json['gender'] as String?,
      birthDate: json['birth_date'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isActive: json['is_active'] == true,
      emailVerifiedAt: json['email_verified_at'] as String?,
      lastLoginAt: json['last_login_at'] as String?,
      roles: roles,
      primaryRole: json['primary_role'] as String?,
      isAdmin: json['is_admin'] == true,
      isCustomer: json['is_customer'] == true,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'phone_verified_at': phoneVerifiedAt,
    'gender': gender,
    'birth_date': birthDate,
    'avatar_url': avatarUrl,
    'is_active': isActive,
    'email_verified_at': emailVerifiedAt,
    'last_login_at': lastLoginAt,
    'roles': roles,
    'primary_role': primaryRole,
    'is_admin': isAdmin,
    'is_customer': isCustomer,
    'created_at': createdAt,
  };

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    phone,
    avatarUrl,
    roles,
    isAdmin,
  ];
}
