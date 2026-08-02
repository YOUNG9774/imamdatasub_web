import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/kd_card.dart';
import '../providers/admin_pricing_provider.dart';

class AdminProviderBalanceScreen extends ConsumerWidget {
  const AdminProviderBalanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balances = ref.watch(adminProviderBalanceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('API Balance')),
      body: SafeArea(
        top: false,
        child: balances.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () =>
                        ref.invalidate(adminProviderBalanceProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (rows) {
            if (rows.isEmpty) {
              return const Center(
                child: Text('No provider balance recorded yet'),
              );
            }
            return RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(adminProviderBalanceProvider),
              child: ListView(
                padding:
                    const EdgeInsets.all(AppDimensions.screenPaddingH),
                children: [
                  Text(
                    'This is the last balance the provider reported after '
                    'a purchase — not a live check. It updates '
                    'automatically every time a data/airtime purchase '
                    'goes through.',
                    style: context.textTheme.bodySmall
                        ?.copyWith(color: AppColors.neutral500),
                  ),
                  const SizedBox(height: 16),
                  ...rows.map((row) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: KDCard(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                row.provider.toUpperCase(),
                                style: context.textTheme.labelMedium
                                    ?.copyWith(
                                  color: AppColors.neutral500,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'NGN${row.balance.toStringAsFixed(2)}',
                                style: context.textTheme.headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Last updated: ${row.lastCheckedAt.toLocal()}',
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: AppColors.neutral400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
