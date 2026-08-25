part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => const [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  final String deviceName;
  final bool remember;
  const AuthLoginRequested({
    required this.email,
    required this.password,
    this.deviceName = 'my-kes-flutter',
    this.remember = false,
  });
  @override
  List<Object?> get props => [email, password, deviceName, remember];
}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String? phone;
  final String password;
  final String passwordConfirmation;
  final String? gender;
  final String? birthDate;
  final String deviceName;
  const AuthRegisterRequested({
    required this.name,
    required this.email,
    this.phone,
    required this.password,
    required this.passwordConfirmation,
    this.gender,
    this.birthDate,
    this.deviceName = 'my-kes-flutter',
  });
  @override
  List<Object?> get props => [
    name,
    email,
    phone,
    password,
    passwordConfirmation,
    gender,
    birthDate,
  ];
}

class AuthForgotPasswordRequested extends AuthEvent {
  final String email;
  const AuthForgotPasswordRequested(this.email);
  @override
  List<Object?> get props => [email];
}

class AuthResetPasswordRequested extends AuthEvent {
  final String email;
  final String token;
  final String password;
  final String passwordConfirmation;
  const AuthResetPasswordRequested({
    required this.email,
    required this.token,
    required this.password,
    required this.passwordConfirmation,
  });
  @override
  List<Object?> get props => [email, token, password, passwordConfirmation];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthUserRefreshed extends AuthEvent {
  const AuthUserRefreshed();
}

class AuthProfileUpdated extends AuthEvent {
  final Map<String, dynamic> changes;
  const AuthProfileUpdated(this.changes);
  @override
  List<Object?> get props => [changes];
}

class AuthPasswordChanged extends AuthEvent {
  final String currentPassword;
  final String newPassword;
  final String newPasswordConfirmation;
  const AuthPasswordChanged({
    required this.currentPassword,
    required this.newPassword,
    required this.newPasswordConfirmation,
  });
  @override
  List<Object?> get props => [
    currentPassword,
    newPassword,
    newPasswordConfirmation,
  ];
}
