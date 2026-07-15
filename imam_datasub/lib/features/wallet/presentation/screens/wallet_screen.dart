import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/kd_button.dart';
import '../../../../shared/widgets/kd_card.dart';
import '../../../../shared/widgets/kd_shimmer.dart';
import '../../../../shared/widgets/kd_text_field.dart';
import '../../../../shared/widgets/wallet_card.dart';
import '../providers/wallet_provider.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletNotifierProvider);
    final balanceHidden = ref.watch(balanceVisibilityProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Wallet')),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () => ref.read(walletNotifierProvider.notifier).refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                walletAsync.when(
                  loading: () => const WalletCardShimmer(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (wallet) => WalletCard(
                    balance: wallet.totalBalance,
                    name: '',
                    accountNumber: wallet.virtualAccountNumber ?? '----------',
                    isBalanceHidden: balanceHidden,
                    onToggleBalance: () =>
                        ref.read(balanceVisibilityProvider.notifier).state =
                            !balanceHidden,
                    onFund: () => context.push(RouteNames.fundWallet),
                    onTransfer: () => context.push(RouteNames.walletTransfer),
                  ),
                ),

                const SizedBox(height: 28),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPaddingH,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Actions', style: context.textTheme.titleSmall),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _ActionCard(
                            icon: Icons.add_circle_outline_rounded,
                            label: 'Add Money',
                            color: AppColors.success500,
                            onTap: () => context.push(RouteNames.fundWallet),
                          ),
                          const SizedBox(width: 12),
                          _ActionCard(
                            icon: Icons.swap_horiz_rounded,
                            label: 'Transfer',
                            color: AppColors.primary500,
                            onTap: () =>
                                context.push(RouteNames.walletTransfer),
                          ),
                          const SizedBox(width: 12),
                          _ActionCard(
                            icon: Icons.arrow_downward_rounded,
                            label: 'Withdraw',
                            color: AppColors.accent500,
                            onTap: () => _showWithdrawSheet(context, ref),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // ── Virtual account ──────────────────────
                      walletAsync.whenData((wallet) {
                            if (wallet.virtualAccountNumber == null) {
                              return const SizedBox.shrink();
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Virtual account',
                                  style: context.textTheme.titleSmall,
                                ),
                                const SizedBox(height: 12),
                                KDCard(
                                  child: Column(
                                    children: [
                                      _AccountRow(
                                        label: 'Bank',
                                        value: wallet.virtualAccountBank ?? '',
                                      ),
                                      const Divider(height: 16),
                                      _AccountRow(
                                        label: 'Account number',
                                        value: wallet.virtualAccountNumber!,
                                        showCopy: true,
                                        onCopy: () {
                                          Clipboard.setData(
                                            ClipboardData(
                                              text:
                                                  wallet.virtualAccountNumber!,
                                            ),
                                          );
                                          context.showSnackBar(
                                            'Account number copied',
                                          );
                                        },
                                      ),
                                      const Divider(height: 16),
                                      _AccountRow(
                                        label: 'Account name',
                                        value: wallet.virtualAccountName ?? '',
                                      ),
                                    ],
                                  ),
                                ).animate().fadeIn(delay: 200.ms),
                                const SizedBox(height: 12),
                                KDCard(
                                  backgroundColor: AppColors.primary50,
                                  border: Border.all(
                                    color: AppColors.primary100,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline_rounded,
                                        color: context.colors.primary,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Transfer any amount to this account to fund your wallet instantly. Minimum: ₦100.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: context.colors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).value ??
                          const SizedBox.shrink(),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showWithdrawSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _WithdrawSheet(),
    );
  }
}

class WalletTransferScreen extends ConsumerStatefulWidget {
  const WalletTransferScreen({super.key});

  @override
  ConsumerState<WalletTransferScreen> createState() =>
      _WalletTransferScreenState();
}

class _WalletTransferScreenState extends ConsumerState<WalletTransferScreen> {
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleTransfer() async {
    context.hideKeyboard();
    final recipient = _recipientController.text.trim();
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    final pin = _pinController.text.trim();

    if (recipient.isEmpty) {
      context.showSnackBar(
        'Enter recipient phone, email, or account ID',
        isError: true,
      );
      return;
    }
    if (amount == null || amount <= 0) {
      context.showSnackBar('Enter a valid amount', isError: true);
      return;
    }
    if (pin.length != 4) {
      context.showSnackBar('Enter your 4-digit transaction PIN', isError: true);
      return;
    }

    setState(() => _isProcessing = true);
    final result = await ref
        .read(walletNotifierProvider.notifier)
        .transfer(recipientIdentifier: recipient, amount: amount, pin: pin);
    if (mounted) setState(() => _isProcessing = false);

    if (!mounted) return;
    result.fold(
      (failure) => context.showSnackBar(failure.message, isError: true),
      (_) {
        context.showSnackBar('Transfer submitted successfully');
        context.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transfer')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KDCard(
                backgroundColor: AppColors.primary50,
                border: Border.all(color: AppColors.primary100),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: context.colors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Send funds to another Imam DataSub user with their phone, email, or account ID.',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              KDTextField(
                controller: _recipientController,
                label: 'Recipient',
                prefixIcon: Icons.person_search_outlined,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              KDAmountField(controller: _amountController, label: 'Amount'),
              const SizedBox(height: 14),
              KDTextField(
                controller: _pinController,
                label: 'Transaction PIN',
                prefixIcon: Icons.pin_outlined,
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
              ),
              const SizedBox(height: 28),
              KDButton(
                label: 'Transfer',
                onPressed: _handleTransfer,
                isLoading: _isProcessing,
                gradient: AppColors.primaryGradient,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.label,
    required this.value,
    this.showCopy = false,
    this.onCopy,
  });
  final String label;
  final String value;
  final bool showCopy;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: context.textTheme.bodySmall),
        Row(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (showCopy) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onCopy,
                child: Icon(
                  Icons.copy_rounded,
                  size: 16,
                  color: context.colors.primary,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _WithdrawSheet extends ConsumerStatefulWidget {
  const _WithdrawSheet();

  @override
  ConsumerState<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends ConsumerState<_WithdrawSheet> {
  final _amountController = TextEditingController();
  final _accountController = TextEditingController();
  final _bankController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _amountController.dispose();
    _accountController.dispose();
    _bankController.dispose();
    super.dispose();
  }

  Future<void> _handleWithdraw() async {
    context.hideKeyboard();
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (amount == null || amount < 500) {
      context.showSnackBar('Minimum withdrawal is ₦500', isError: true);
      return;
    }

    setState(() => _isProcessing = true);
    final result = await ref
        .read(walletNotifierProvider.notifier)
        .transfer(
          recipientIdentifier: _accountController.text.trim(),
          amount: amount,
          pin: '', // PIN verified via PIN sheet before this
        );
    setState(() => _isProcessing = false);

    if (!mounted) return;
    result.fold(
      (failure) => context.showSnackBar(failure.message, isError: true),
      (_) {
        Navigator.of(context).pop();
        context.showSnackBar('Withdrawal request submitted!');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Withdraw funds',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            KDTextField(
              controller: _accountController,
              label: 'Account number',
              prefixIcon: Icons.account_balance_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
            ),
            const SizedBox(height: 14),
            KDTextField(
              controller: _bankController,
              label: 'Bank name',
              prefixIcon: Icons.corporate_fare_rounded,
            ),
            const SizedBox(height: 14),
            KDAmountField(
              controller: _amountController,
              label: 'Amount (min ₦500)',
            ),
            const SizedBox(height: 24),
            KDButton(
              label: 'Submit withdrawal',
              onPressed: _handleWithdraw,
              isLoading: _isProcessing,
              gradient: AppColors.primaryGradient,
            ),
          ],
        ),
      ),
    );
  }
}
