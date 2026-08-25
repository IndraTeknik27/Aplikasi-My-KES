import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_kes/core/api/api_client.dart';
import 'package:my_kes/features/auth/bloc/auth_bloc.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // flutter_secure_storage talks to a platform channel; in tests the native
  // side isn't present, so we install a no-op handler. Reads return null
  // and writes are silently accepted.
  setUp(() {
    const channel = MethodChannel('plugins.flutter.io/secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
  });

  late _MockApiClient api;

  setUp(() {
    api = _MockApiClient();
  });

  // Build a success payload for `/auth/login` and `/auth/me`.
  ApiResponse<Map<String, dynamic>> loginResponse() {
    return ApiResponse<Map<String, dynamic>>(
      success: true,
      message: 'OK',
      statusCode: 200,
      data: {
        'access_token': 'tok-123',
        'token_type': 'Bearer',
        'user': {
          'id': 1,
          'name': 'Tester',
          'email': 't@example.com',
          'is_active': true,
          'roles': ['customer'],
          'is_admin': false,
          'is_customer': true,
        },
      },
    );
  }

  ApiResponse<Map<String, dynamic>> meResponse() => loginResponse();

  group('AuthBloc.login', () {
    blocTest<AuthBloc, AuthState>(
      'emits [loading, authenticated] on successful login',
      build: () {
        when(
          () => api.post<Map<String, dynamic>>(
            any(),
            body: any(named: 'body'),
            query: any(named: 'query'),
            headers: any(named: 'headers'),
          ),
        ).thenAnswer((_) async => loginResponse());
        when(
          () => api.get<Map<String, dynamic>>(
            any(),
            query: any(named: 'query'),
            headers: any(named: 'headers'),
          ),
        ).thenAnswer((_) async => meResponse());
        return AuthBloc(apiClient: api);
      },
      act: (bloc) => bloc.add(
        const AuthLoginRequested(email: 't@example.com', password: 'secret123'),
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>().having(
          (s) => s.user.email,
          'user.email',
          't@example.com',
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, error] when API throws 401',
      build: () {
        when(
          () => api.post<Map<String, dynamic>>(
            any(),
            body: any(named: 'body'),
            query: any(named: 'query'),
            headers: any(named: 'headers'),
          ),
        ).thenThrow(
          ApiException(message: 'Email atau password salah.', statusCode: 401),
        );
        return AuthBloc(apiClient: api);
      },
      act: (bloc) => bloc.add(
        const AuthLoginRequested(email: 't@example.com', password: 'wrong'),
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>().having(
          (e) => e.message,
          'message',
          contains('Email atau password'),
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'returns field errors for 422 validation',
      build: () {
        when(
          () => api.post<Map<String, dynamic>>(
            any(),
            body: any(named: 'body'),
            query: any(named: 'query'),
            headers: any(named: 'headers'),
          ),
        ).thenThrow(
          ApiException(
            message: 'Validation failed',
            statusCode: 422,
            errors: {
              'email': ['Email wajib diisi'],
            },
          ),
        );
        return AuthBloc(apiClient: api);
      },
      act: (bloc) =>
          bloc.add(const AuthLoginRequested(email: '', password: '')),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>().having(
          (e) => e.fieldErrors['email'],
          'email error',
          'Email wajib diisi',
        ),
      ],
    );
  });

  group('User model', () {
    test('User.fromJson tolerates missing optional fields', () {
      final json = jsonEncode({
        'id': 1,
        'name': 'x',
        'email': 'x@y.com',
        'is_active': true,
        'is_admin': false,
        'is_customer': true,
      });
      final u = User.fromJson(jsonDecode(json) as Map<String, dynamic>);
      expect(u.id, 1);
      expect(u.email, 'x@y.com');
      expect(u.phone, isNull);
      expect(u.roles, ['customer']);
      expect(u.initials, 'X');
    });
  });
}
