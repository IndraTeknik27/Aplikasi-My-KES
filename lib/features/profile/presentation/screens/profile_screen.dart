import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/common.dart';
import '../../../../shared/widgets/states.dart';
import '../../../auth/bloc/auth_bloc.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            return const LoadingIndicator();
          }
          final u = state.user;
          return RefreshIndicator(
            onRefresh: () async =>
                context.read<AuthBloc>().add(const AuthUserRefreshed()),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _ProfileCard(user: u),
                const SizedBox(height: AppSpacing.lg),
                _Section(
                  items: [
                    _Item(
                      icon: Icons.edit,
                      label: 'Edit Profil',
                      onTap: () => context.push(Routes.editProfile),
                    ),
                    _Item(
                      icon: Icons.location_on_outlined,
                      label: 'Alamat Pengiriman',
                      onTap: () => context.push(Routes.addresses),
                    ),
                    _Item(
                      icon: Icons.shopping_bag_outlined,
                      label: 'Pesanan Saya',
                      onTap: () => context.push(Routes.orders),
                    ),
                    _Item(
                      icon: Icons.favorite_outline,
                      label: 'Wishlist',
                      onTap: () => context.push(Routes.wishlist),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _Section(
                  items: [
                    _Item(
                      icon: Icons.help_outline,
                      label: 'Bantuan & FAQ',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Fitur dalam pengembangan.')),
                        );
                      },
                    ),
                    _Item(
                      icon: Icons.policy_outlined,
                      label: 'Kebijakan Privasi',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Fitur dalam pengembangan.')),
                        );
                      },
                    ),
                    _Item(
                      icon: Icons.info_outline,
                      label: 'Tentang Aplikasi',
                      onTap: () => _aboutDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton.icon(
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Keluar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: Text(
                    'My KES v1.0.0',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keluar Akun?'),
        content: const Text(
          'Anda akan keluar dari akun ini di perangkat ini. Anda bisa masuk lagi kapan saja.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<AuthBloc>().add(const AuthLogoutRequested());
    }
  }

  void _aboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: '1.0.0',
      applicationLegalese:
          '© ${DateTime.now().year} ${AppConstants.appTagline}',
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final User user;
  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          if (user.avatarUrl != null)
            ClipOval(
              child: SafeNetworkImage(
                url: user.avatarUrl,
                width: 60,
                height: 60,
                borderRadius: const BorderRadius.all(Radius.circular(30)),
              ),
            )
          else
            AvatarPlaceholder(label: user.initials, size: 60),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (user.phone != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    user.phone!,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final List<_Item> items;
  const _Section({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: AppColors.surface,
        child: Column(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              items[i],
              if (i != items.length - 1) const Divider(height: 1, indent: 50),
            ],
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _Item({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        size: 18,
        color: AppColors.textMuted,
      ),
    );
  }
}
