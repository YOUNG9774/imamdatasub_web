import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/kd_button.dart';
import '../../../../shared/widgets/kd_card.dart';
import '../../../../shared/widgets/kd_text_field.dart';
import '../providers/wallet_provider.dart';

const List<double> _quickAmounts = [500, 1000, 2000, 5000, 10000, 20000];

enum FundMethod { bankTransfer, cardPayment }

class FundWalletScreen extends ConsumerStatefulWidget {
  const FundWalletScreen({super.key});

  @override
  ConsumerState<FundWalletScreen> createState() => _FundWalletScreenState();
}

class _FundWalletScreenState extends ConsumerState<FundWalletScreen> {
  final _amountController = TextEditingController();
  FundMethod _selectedMethod = FundMethod.bankTransfer;
  double _selectedAmount = 0;
  bool _isProcessing = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  bool get _canProceed => _selectedAmount >= 100;

  Future<void> _handleFund() async {
    context.hideKeyboard();
    if (!_canProceed) return;

    setState(() => _isProcessing = true);
    final result = await ref
        .read(walletNotifierProvider.notifier)
        .fundWallet(
          amount: _selectedAmount,
          paymentMethod: _selectedMethod.name,
        );
    setState(() => _isProcessing = false);

    if (!mounted) return;

    result.fold(
      (failure) => context.showSnackBar(failure.message, isError: true),
      (data) {
        // In production: open payment gateway URL from data['payment_url']
        // For bank transfer: show account details from data
        final paymentUrl = data['payment_url']?.toString();
        final message = data['message']?.toString() ??
            'Please complete payment to fund your wallet.';
        context.showSnackBar(message);
        context.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.fundWallet)),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.amount, style: context.textTheme.titleSmall),
              const SizedBox(height: 10),
              KDAmountField(
                controller: _amountController,
                onChanged: (v) => setState(() {
                  _selectedAmount =
                      double.tryParse(v.replaceAll(',', '')) ?? 0;
                }),
                validator: (v) =>
                    AppValidators.amount(v, min: 100, max: 200000),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickAmounts.map((amount) {
                  final isSelected = _selectedAmount == amount;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedAmount = amount);
                      _amountController.text =
                          amount.toStringAsFixed(0);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? context.colors.primary
                            : AppColors.primary50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        AppFormatters.formatAmount(amount),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : context.colors.primary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),
              Text('Payment method',
                  style: context.textTheme.titleSmall),
              const SizedBox(height: 12),

              _MethodCard(
                icon: Icons.account_balance_outlined,
                title: 'Bank transfer',
                subtitle: 'Transfer directly to your virtual account',
                isSelected: _selectedMethod == FundMethod.bankTransfer,
                onTap: () => setState(
                    () => _selectedMethod = FundMethod.bankTransfer),
              ),
              const SizedBox(height: 10),
              _MethodCard(
                icon: Icons.credit_card_rounded,
                title: 'Card payment',
                subtitle: 'Pay with debit or credit card via Paystack',
                isSelected: _selectedMethod == FundMethod.cardPayment,
                onTap: () => setState(
                    () => _selectedMethod = FundMethod.cardPayment),
              ),

              if (_selectedAmount > 0) ...[
                const SizedBox(height: 24),
                KDCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Amount to add'),
                      Text(
                        AppFormatters.formatAmount(_selectedAmount),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: context.colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
          child: KDButton(
            label: _selectedAmount > 0
                ? 'Fund ${AppFormatters.formatAmount(_selectedAmount)}'
                : 'Enter amount to continue',
            onPressed: _canProceed ? _handleFund : null,
            isLoading: _isProcessing,
            gradient: AppColors.primaryGradient,
          ),
        ),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? context.colors.primary.withValues(alpha: 0.05)
              : (context.isDark
                  ? AppColors.darkCardSurface
                  : AppColors.lightCardSurface),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? context.colors.primary
                : (context.isDark
                    ? AppColors.darkDivider
                    : AppColors.neutral200),
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? context.colors.primary.withValues(alpha: 0.1)
                    : AppColors.neutral100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: isSelected
                      ? context.colors.primary
                      : AppColors.neutral500,
                  size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.neutral500)),
                ],
              ),
            ),
            Radio<FundMethod>(
              value: _selectedMethod,
              groupValue: isSelected ? _selectedMethod : null,
              onChanged: (_) => onTap(),
              activeColor: context.colors.primary,
            ),
          ],
        ),
      ),
    );
  }

  FundMethod get _selectedMethod => isSelected
      ? (icon == Icons.credit_card_rounded
          ? FundMethod.cardPayment
          : FundMethod.bankTransfer)
      : FundMethod.bankTransfer;
}
