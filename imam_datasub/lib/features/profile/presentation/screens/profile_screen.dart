import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/config/app_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection.dart';
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
      appBar: AppBar(
        title: const Text(AppStrings.profile),
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Text('🇬🇧'),
            label: const Text('En'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.screenPaddingH,
          ),
          child: Column(
            children: [
              const SizedBox(height: 18),
              _ProfileHeader(user: user),
              const SizedBox(height: 24),
              _SectionHeader(title: 'General Settings'),
              const SizedBox(height: 8),
              KDCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _ProfileTile(
                      icon: Icons.person_outline_rounded,
                      title: 'Profile',
                      subtitle: 'Your personal information',
                      onTap: () => context.push(RouteNames.editProfile),
                    ),
                    const Divider(height: 1, indent: 72),
                    _ProfileTile(
                      icon: Icons.price_change_outlined,
                      title: 'Pricing',
                      subtitle: admin == null
                          ? 'View available data plans'
                          : 'Manage data selling prices',
                      onTap: () => context.push(
                        admin == null
                            ? RouteNames.buyData
                            : RouteNames.adminDataPricing,
                      ),
                    ),
                    const Divider(height: 1, indent: 72),
                    _ProfileTile(
                      icon: Icons.code_rounded,
                      title: 'Code To Check Balance',
                      subtitle: 'Codes to check data and airtime balance',
                      onTap: () => _showBalanceCodes(context),
                    ),
                    const Divider(height: 1, indent: 72),
                    _ProfileTile(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Update Virtual Account As required by CBN',
                      subtitle:
                          'Complete KYC to create or refresh your account',
                      trailing: _KycBadge(
                        status: user?.kycStatus ?? KycStatus.unverified,
                        compact: true,
                      ),
                      onTap: () => context.push(RouteNames.kyc),
                    ),
                    const Divider(height: 1, indent: 72),
                    _ProfileTile(
                      icon: Icons.call_outlined,
                      title: 'Contact Us',
                      subtitle: 'Contact our support team',
                      onTap: () => _openWhatsApp(AppConfig.supportWhatsApp),
                    ),
                    const Divider(height: 1, indent: 72),
                    _ProfileTile(
                      icon: Icons.support_agent_rounded,
                      title: 'Log Complaint',
                      subtitle: 'Open support and complaint channels',
                      onTap: () => context.push(RouteNames.support),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _SectionHeader(title: 'Security'),
              const SizedBox(height: 8),
              KDCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _ProfileTile(
                      icon: Icons.lock_outline_rounded,
                      title: AppStrings.changePassword,
                      subtitle: 'Update your login password',
                      onTap: () => context.push(RouteNames.changePassword),
                    ),
                    const Divider(height: 1, indent: 72),
                    _ProfileTile(
                      icon: Icons.pin_outlined,
                      title: 'Transaction PIN',
                      subtitle: 'Create or change payment PIN',
                      onTap: () => context.push(RouteNames.changePin),
                    ),
                    const Divider(height: 1, indent: 72),
                    _ProfileTile(
                      icon: Icons.fingerprint_rounded,
                      title: AppStrings.biometricAuth,
                      subtitle: 'Fingerprint or face unlock',
                      onTap: () => context.push(RouteNames.security),
                    ),
                    const Divider(height: 1, indent: 72),
                    _ProfileTile(
                      icon: Icons.notifications_outlined,
                      title: AppStrings.notifications,
                      subtitle: 'Transaction and app alerts',
                      onTap: () => context.push(RouteNames.notifications),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _SectionHeader(title: 'Legal & Account'),
              const SizedBox(height: 8),
              KDCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _ProfileTile(
                      icon: Icons.privacy_tip_outlined,
                      title: AppStrings.privacyPolicy,
                      subtitle: 'How IMAM DATASUB uses and protects data',
                      onTap: () => context.push(RouteNames.privacyPolicy),
                    ),
                    const Divider(height: 1, indent: 72),
                    _ProfileTile(
                      icon: Icons.description_outlined,
                      title: AppStrings.termsOfService,
                      subtitle: 'Service rules, wallet funding and refunds',
                      onTap: () => context.push(RouteNames.terms),
                    ),
                    const Divider(height: 1, indent: 72),
                    _ProfileTile(
                      icon: Icons.delete_outline_rounded,
                      iconColor: AppColors.error500,
                      title: 'Deactivate / Delete Account',
                      titleColor: AppColors.error500,
                      subtitle: 'Request permanent account removal',
                      onTap: () => _confirmDeleteAccount(context, ref),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              KDCard(
                padding: EdgeInsets.zero,
                child: _ProfileTile(
                  icon: Icons.logout_rounded,
                  iconColor: AppColors.error500,
                  title: AppStrings.signOut,
                  titleColor: AppColors.error500,
                  showChevron: false,
                  onTap: () => _confirmSignOut(context, ref),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  static void _showBalanceCodes(BuildContext context) {
    const rows = [
      ('MTN Data', '*323*4#'),
      ('MTN Airtime', '*310#'),
      ('Airtel Data', '*323#'),
      ('Airtel Airtime', '*310#'),
      ('Glo Data', '*323#'),
      ('Glo Airtime', '*310#'),
      ('9mobile Data', '*323#'),
      ('9mobile Airtime', '*310#'),
    ];
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Balance Codes',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            ...rows.map(
              (row) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  row.$1,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                trailing: TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: row.$2));
                    if (context.mounted)
                      context.showSnackBar('Copied ${row.$2}');
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: Text(row.$2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _openWhatsApp(String phone) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    await launchUrl(
      Uri.parse('https://wa.me/$digits?text=Hello%20IMAM%20DATASUB%20Support'),
      mode: LaunchMode.externalApplication,
    );
  }

  static void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog<void>(
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

  static void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This will disable your login and anonymize your personal profile. Transaction records may be retained for audit and compliance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref
                    .read(dioClientProvider)
                    .delete<Map<String, dynamic>>(AppEndpoints.deleteAccount);
                await ref.read(authNotifierProvider.notifier).logout();
                if (context.mounted) {
                  context.showSnackBar('Account deleted successfully');
                  context.go(RouteNames.login);
                }
              } on DioException catch (e) {
                if (context.mounted) {
                  context.showSnackBar(
                    e.response?.data['message']?.toString() ??
                        'Could not delete account',
                    isError: true,
                  );
                }
              } catch (_) {
                if (context.mounted)
                  context.showSnackBar(
                    'Could not delete account',
                    isError: true,
                  );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error500),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});
  final UserEntity? user;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: AppDimensions.avatarXXL / 2,
          backgroundColor: AppColors.primary100,
          backgroundImage: user?.photoUrl != null
              ? CachedNetworkImageProvider(user!.photoUrl!)
              : null,
          child: user?.photoUrl == null
              ? Text(
                  user?.initials ?? 'ID',
                  style: const TextStyle(
                    color: AppColors.primary700,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 14),
        Text(
          user?.fullName.toUpperCase() ?? 'IMAM DATASUB',
          textAlign: TextAlign.center,
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user?.referralCode.isNotEmpty == true
              ? user!.referralCode
              : (user?.email ?? ''),
          style: context.textTheme.bodyLarge?.copyWith(
            color: AppColors.neutral500,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        _KycBadge(status: user?.kycStatus ?? KycStatus.unverified),
      ],
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
    this.subtitle,
    this.iconColor,
    this.titleColor,
    this.trailing,
    this.showChevron = true,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? titleColor;
  final Widget? trailing;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? context.colors.primary;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 16,
          color: titleColor,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: const TextStyle(color: AppColors.neutral500),
            ),
      trailing:
          trailing ??
          (showChevron
              ? const Icon(Icons.chevron_right_rounded, size: 28)
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
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
