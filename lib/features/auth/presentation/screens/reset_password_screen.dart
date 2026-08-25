import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../shared/widgets/common.dart';
import '../../bloc/auth_bloc.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _token = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _showPass = false;

  @override
  void dispose() {
    _email.dispose();
    _token.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthResetPasswordRequested(
        email: _email.text.trim(),
        token: _token.text.trim(),
        password: _pass.text,
        passwordConfirmation: _confirm.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Reset Password'),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (p, c) => c is AuthError || c is AuthResetPasswordSuccess,
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
          if (state is AuthResetPasswordSuccess) {
            showDialog<void>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Password berhasil diubah'),
                content: const Text('Silakan login dengan password baru Anda.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.go(Routes.login);
                    },
                    child: const Text('Login'),
                  ),
                ],
              ),
            );
          }
        },
        builder: (context, state) {
          final loading = state is AuthLoading;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Buat password baru',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Masukkan token yang dikirim ke email Anda beserta password baru.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Email wajib diisi' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _token,
                    decoration: const InputDecoration(
                      labelText: 'Token Reset',
                      prefixIcon: Icon(Icons.vpn_key_outlined),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Token wajib diisi' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _pass,
                    obscureText: !_showPass,
                    decoration: InputDecoration(
                      labelText: 'Password Baru',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPass ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => setState(() => _showPass = !_showPass),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Password wajib diisi';
                      }
                      if (v.length < 8) return 'Password minimal 8 karakter';
                      if (!v.contains(RegExp(r'[A-Z]'))) {
                        return 'Harus ada huruf besar';
                      }
                      if (!v.contains(RegExp(r'[a-z]'))) {
                        return 'Harus ada huruf kecil';
                      }
                      if (!v.contains(RegExp(r'[0-9]'))) {
                        return 'Harus ada angka';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _confirm,
                    obscureText: !_showPass,
                    decoration: const InputDecoration(
                      labelText: 'Konfirmasi Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (v) =>
                        v == _pass.text ? null : 'Password tidak cocok',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  LoadingButton(
                    onPressed: loading ? null : _submit,
                    loading: loading,
                    child: const Text('Simpan Password Baru'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
