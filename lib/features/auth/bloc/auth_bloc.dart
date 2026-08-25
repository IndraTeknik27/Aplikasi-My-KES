import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/storage/secure_storage.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({ApiClient? apiClient}) : super(const AuthInitial()) {
    _api = apiClient ?? ApiClient.instance;
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthForgotPasswordRequested>(_onForgotPassword);
    on<AuthResetPasswordRequested>(_onResetPassword);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthUserRefreshed>(_onUserRefreshed);
    on<AuthProfileUpdated>(_onProfileUpdated);
    on<AuthPasswordChanged>(_onPasswordChanged);
  }

  late final ApiClient _api;

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final token = await SecureStorage.readToken();
      if (token == null || token.isEmpty) {
        emit(const AuthUnauthenticated());
        return;
      }
      final res = await _api.get<Map<String, dynamic>>(ApiEndpoints.me);
      final userJson = res.data;
      if (userJson == null) {
        emit(const AuthUnauthenticated());
        return;
      }
      await SecureStorage.saveUser(jsonEncode(userJson));
      emit(AuthAuthenticated(User.fromJson(userJson), token));
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await SecureStorage.clearAuth();
        emit(const AuthUnauthenticated());
        return;
      }
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final res = await _api.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        body: {
          'email': event.email,
          'password': event.password,
          'device_name': event.deviceName,
          'remember': event.remember,
        },
      );
      final data = res.data;
      if (data == null) {
        emit(const AuthError('Login gagal. Coba lagi.'));
        return;
      }
      final token = (data['access_token'] as String?) ?? '';
      final userJson = data['user'] as Map<String, dynamic>?;
      if (token.isEmpty || userJson == null) {
        emit(const AuthError('Login gagal. Token tidak ditemukan.'));
        return;
      }
      final user = User.fromJson(userJson);
      emit(AuthAuthenticated(user, token));
      // Best-effort persistence — failure here just means the user has to
      // log in again next launch.
      try {
        await SecureStorage.saveToken(token);
        await SecureStorage.saveUser(jsonEncode(userJson));
      } catch (_) {
        /* ignore */
      }
    } on ApiException catch (e) {
      emit(AuthError(e.message, fieldErrors: e.fieldErrors()));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onRegister(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final res = await _api.post<Map<String, dynamic>>(
        ApiEndpoints.register,
        body: {
          'name': event.name,
          'email': event.email,
          'phone': event.phone,
          'password': event.password,
          'password_confirmation': event.passwordConfirmation,
          if (event.gender != null) 'gender': event.gender,
          if (event.birthDate != null) 'birth_date': event.birthDate,
          'device_name': event.deviceName,
        },
      );
      final data = res.data;
      if (data == null) {
        emit(const AuthError('Registrasi gagal. Coba lagi.'));
        return;
      }
      final token = (data['access_token'] as String?) ?? '';
      final userJson = data['user'] as Map<String, dynamic>?;
      if (token.isEmpty || userJson == null) {
        emit(const AuthError('Registrasi gagal. Token tidak ditemukan.'));
        return;
      }
      final user = User.fromJson(userJson);
      emit(AuthAuthenticated(user, token));
      try {
        await SecureStorage.saveToken(token);
        await SecureStorage.saveUser(jsonEncode(userJson));
      } catch (_) {
        /* ignore */
      }
    } on ApiException catch (e) {
      emit(AuthError(e.message, fieldErrors: e.fieldErrors()));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onForgotPassword(
    AuthForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _api.post<Map<String, dynamic>>(
        ApiEndpoints.forgotPassword,
        body: {'email': event.email},
      );
      emit(const AuthForgotPasswordSent());
    } on ApiException catch (e) {
      emit(AuthError(e.message, fieldErrors: e.fieldErrors()));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onResetPassword(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _api.post<Map<String, dynamic>>(
        ApiEndpoints.resetPassword,
        body: {
          'email': event.email,
          'token': event.token,
          'password': event.password,
          'password_confirmation': event.passwordConfirmation,
        },
      );
      emit(const AuthResetPasswordSuccess());
    } on ApiException catch (e) {
      emit(AuthError(e.message, fieldErrors: e.fieldErrors()));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _api.post<dynamic>(ApiEndpoints.logout);
    } catch (_) {
      // even if server call fails, wipe local creds
    } finally {
      await SecureStorage.clearAuth();
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onUserRefreshed(
    AuthUserRefreshed event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final res = await _api.get<Map<String, dynamic>>(ApiEndpoints.me);
      final userJson = res.data;
      if (userJson != null) {
        await SecureStorage.saveUser(jsonEncode(userJson));
        final token = await SecureStorage.readToken() ?? '';
        emit(AuthAuthenticated(User.fromJson(userJson), token));
      }
    } catch (_) {
      /* silent */
    }
  }

  Future<void> _onProfileUpdated(
    AuthProfileUpdated event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final res = await _api.put<Map<String, dynamic>>(
        ApiEndpoints.updateProfile,
        body: event.changes,
      );
      final userJson = res.data;
      if (userJson != null) {
        await SecureStorage.saveUser(jsonEncode(userJson));
        final token = await SecureStorage.readToken() ?? '';
        emit(AuthAuthenticated(User.fromJson(userJson), token));
      }
    } on ApiException catch (e) {
      emit(AuthError(e.message, fieldErrors: e.fieldErrors()));
    }
  }

  Future<void> _onPasswordChanged(
    AuthPasswordChanged event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _api.put<dynamic>(
        ApiEndpoints.updatePassword,
        body: {
          'current_password': event.currentPassword,
          'password': event.newPassword,
          'password_confirmation': event.newPasswordConfirmation,
        },
      );
      emit(const AuthPasswordChangedSuccess());
    } on ApiException catch (e) {
      emit(AuthError(e.message, fieldErrors: e.fieldErrors()));
    }
  }
}
