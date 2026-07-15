import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/kd_card.dart';
import '../../../admin/presentation/providers/admin_pricing_provider.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final admin = ref.watch(adminMeProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profile)),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.screenPaddingH,
          ),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ── Avatar ────────────────────────────────────
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: AppDimensions.avatarXXL / 2,
                      backgroundColor: AppColors.primary100,
                      backgroundImage: user?.photoUrl != null
                          ? CachedNetworkImageProvider(user!.photoUrl!)
                          : null,
                      child: user?.photoUrl == null
                          ? Text(
                              user?.initials ?? 'KD',
                              style: const TextStyle(
                                color: AppColors.primary700,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => context.push(RouteNames.editProfile),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: context.colors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.colors.surface,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Text(
                user?.fullName ?? '',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? '',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: AppColors.neutral500,
                ),
              ),
              const SizedBox(height: 8),
              _KycBadge(status: user?.kycStatus ?? KycStatus.unverified),

              const SizedBox(height: 24),

              // ── Account section ──────────────────────────
              _SectionHeader(title: 'Account'),
              const SizedBox(height: 8),
              KDCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _ProfileTile(
                      icon: Icons.person_outline_rounded,
                      title: AppStrings.editProfile,
                      onTap: () => context.push(RouteNames.editProfile),
                    ),
                    const Divider(height: 1, indent: 60),
                    _ProfileTile(
                      icon: Icons.verified_user_outlined,
                      title: 'KYC verification',
                      trailing: _KycBadge(
                        status: user?.kycStatus ?? KycStatus.unverified,
                        compact: true,
                      ),
                      onTap: () => context.push(RouteNames.kyc),
                    ),
                    const Divider(height: 1, indent: 60),
                    _ProfileTile(
                      icon: Icons.notifications_outlined,
                      title: AppStrings.notifications,
                      onTap: () => context.push(RouteNames.notifications),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Security section ─────────────────────────
              _SectionHeader(title: 'Security'),
              const SizedBox(height: 8),
              KDCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _ProfileTile(
                      icon: Icons.lock_outline_rounded,
                      title: AppStrings.changePassword,
                      onTap: () => context.push(RouteNames.changePassword),
                    ),
                    const Divider(height: 1, indent: 60),
                    _ProfileTile(
                      icon: Icons.pin_outlined,
                      title: 'Transaction PIN',
                      onTap: () => context.push(RouteNames.changePin),
                    ),
                    const Divider(height: 1, indent: 60),
                    _ProfileTile(
                      icon: Icons.fingerprint_rounded,
                      title: AppStrings.biometricAuth,
                      onTap: () => context.push(RouteNames.security),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Support & More ───────────────────────────
              if (admin != null) ...[
                _SectionHeader(title: 'Admin'),
                const SizedBox(height: 8),
                KDCard(
                  padding: EdgeInsets.zero,
                  child: _ProfileTile(
                    icon: Icons.price_change_outlined,
                    title: 'Data pricing',
                    trailing: Text(
                      admin.role,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral500,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onTap: () => context.push(RouteNames.adminDataPricing),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              _SectionHeader(title: 'Support'),
              const SizedBox(height: 8),
              KDCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _ProfileTile(
                      icon: Icons.headset_mic_outlined,
                      title: AppStrings.support,
                      onTap: () => context.push(RouteNames.support),
                    ),
                    const Divider(height: 1, indent: 60),
                    _ProfileTile(
                      icon: Icons.settings_outlined,
                      title: AppStrings.settings,
                      onTap: () => context.push(RouteNames.settings),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Sign out ─────────────────────────────────
              KDCard(
                padding: EdgeInsets.zero,
                child: _ProfileTile(
                  icon: Icons.logout_rounded,
                  iconColor: AppColors.error500,
                  title: AppStrings.signOut,
                  titleColor: AppColors.error500,
                  onTap: () => _confirmSignOut(context, ref),
                  showChevron: false,
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) context.go(RouteNames.login);
            },
            child: const Text(
              'Sign out',
              style: TextStyle(color: AppColors.error500),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: context.textTheme.titleSmall?.copyWith(
          color: AppColors.neutral500,
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.titleColor,
    this.trailing,
    this.showChevron = true,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? titleColor;
  final Widget? trailing;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (iconColor ?? context.colors.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor ?? context.colors.primary, size: 18),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, color: titleColor),
      ),
      trailing:
          trailing ??
          (showChevron
              ? Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.neutral400,
                  size: 20,
                )
              : null),
    );
  }
}

class _KycBadge extends StatelessWidget {
  const _KycBadge({required this.status, this.compact = false});
  final KycStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (status) {
      KycStatus.verified => (
        'Verified',
        AppColors.success700,
        AppColors.success50,
      ),
      KycStatus.pending => (
        'Pending',
        AppColors.warning700,
        AppColors.warning50,
      ),
      KycStatus.rejected => ('Rejected', AppColors.error700, AppColors.error50),
      KycStatus.unverified => (
        'Unverified',
        AppColors.neutral600,
        AppColors.neutral100,
      ),
    };

    final (icon) = switch (status) {
      KycStatus.verified => Icons.verified_rounded,
      KycStatus.pending => Icons.schedule_rounded,
      KycStatus.rejected => Icons.cancel_rounded,
      KycStatus.unverified => Icons.info_outline_rounded,
    };

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
