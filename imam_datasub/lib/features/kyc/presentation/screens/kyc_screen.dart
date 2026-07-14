import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../../core/config/app_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/kd_button.dart';
import '../../../../shared/widgets/kd_card.dart';
import '../../../../shared/widgets/kd_text_field.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// ── KYC step provider ──────────────────────────────────────
enum KycStep { bvn, nin, document, selfie, complete }

class KycNotifier extends StateNotifier<KycStep> {
  KycNotifier() : super(KycStep.bvn);
  void next() {
    final steps = KycStep.values;
    final idx = steps.indexOf(state);
    if (idx < steps.length - 1) state = steps[idx + 1];
  }
  void reset() => state = KycStep.bvn;
}

final kycStepProvider =
    StateNotifierProvider.autoDispose<KycNotifier, KycStep>(
        (_) => KycNotifier());

class _KycSubmitNotifier extends StateNotifier<bool> {
  _KycSubmitNotifier() : super(false);
  void setLoading(bool v) => state = v;
}

final _kycLoadingProvider =
    StateNotifierProvider.autoDispose<_KycSubmitNotifier, bool>(
        (_) => _KycSubmitNotifier());

class KycScreen extends ConsumerStatefulWidget {
  const KycScreen({super.key});

  @override
  ConsumerState<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends ConsumerState<KycScreen> {
  final _bvnController = TextEditingController();
  final _ninController = TextEditingController();
  XFile? _idDocument;
  XFile? _selfie;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _bvnController.dispose();
    _ninController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    final file =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) setState(() => _idDocument = file);
  }

  Future<void> _captureSelfie() async {
    final file =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (file != null) setState(() => _selfie = file);
  }

  Future<void> _submitStep(KycStep step) async {
    final dio = ref.read(dioClientProvider);
    ref.read(_kycLoadingProvider.notifier).setLoading(true);

    try {
      switch (step) {
        case KycStep.bvn:
          await dio.post(
              AppEndpoints.verifyBvn,
              data: {'bvn': _bvnController.text.trim()});
          break;
        case KycStep.nin:
          await dio.post(
              AppEndpoints.verifyNin,
              data: {'nin': _ninController.text.trim()});
          break;
        case KycStep.document:
          if (_idDocument == null) return;
          final bytes = await _idDocument!.readAsBytes();
          final formData = FormData.fromMap({
            'document': MultipartFile.fromBytes(bytes,
                filename: _idDocument!.name),
            'type': 'government_id',
          });
          await dio.post(AppEndpoints.uploadKycDocument, data: formData);
          break;
        case KycStep.selfie:
          if (_selfie == null) return;
          final bytes = await _selfie!.readAsBytes();
          final formData = FormData.fromMap({
            'selfie': MultipartFile.fromBytes(bytes,
                filename: _selfie!.name),
          });
          await dio.post(AppEndpoints.uploadSelfie, data: formData);
          break;
        case KycStep.complete:
          break;
      }

      ref.read(kycStepProvider.notifier).next();
    } catch (e) {
      if (mounted) {
        context.showSnackBar(
            'Submission failed. Please try again.', isError: true);
      }
    } finally {
      ref.read(_kycLoadingProvider.notifier).setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = ref.watch(kycStepProvider);
    final isLoading = ref.watch(_kycLoadingProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('KYC Verification')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ── Progress bar ───────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step ${step.index + 1} of ${KycStep.values.length - 1}',
                    style: context.textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (step.index) /
                        (KycStep.values.length - 2),
                    backgroundColor: AppColors.neutral200,
                    valueColor: AlwaysStoppedAnimation(
                        context.colors.primary),
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 6,
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPaddingH),
                child: _buildStep(step, user),
              ),
            ),

            if (step != KycStep.complete)
              Padding(
                padding:
                    const EdgeInsets.all(AppDimensions.screenPaddingH),
                child: SafeArea(
                  top: false,
                  child: KDButton(
                    label: step == KycStep.selfie
                        ? 'Submit verification'
                        : 'Continue',
                    onPressed: _canSubmit(step)
                        ? () => _submitStep(step)
                        : null,
                    isLoading: isLoading,
                    gradient: AppColors.primaryGradient,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _canSubmit(KycStep step) {
    switch (step) {
      case KycStep.bvn:
        return _bvnController.text.length == 11;
      case KycStep.nin:
        return _ninController.text.length == 11;
      case KycStep.document:
        return _idDocument != null;
      case KycStep.selfie:
        return _selfie != null;
      case KycStep.complete:
        return false;
    }
  }

  Widget _buildStep(KycStep step, UserEntity? user) {
    switch (step) {
      case KycStep.bvn:
        return _StepContent(
          icon: Icons.fingerprint_rounded,
          title: 'BVN verification',
          subtitle:
              'Enter your Bank Verification Number. We use this to confirm your identity.',
          child: Column(
            children: [
              const SizedBox(height: 20),
              KDTextField(
                controller: _bvnController,
                label: 'BVN',
                hint: '12345678901',
                prefixIcon: Icons.numbers_rounded,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                validator: AppValidators.bvn,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        );

      case KycStep.nin:
        return _StepContent(
          icon: Icons.badge_rounded,
          title: 'NIN verification',
          subtitle:
              'Enter your National Identification Number to complete identity verification.',
          child: Column(
            children: [
              const SizedBox(height: 20),
              KDTextField(
                controller: _ninController,
                label: 'NIN',
                hint: '12345678901',
                prefixIcon: Icons.numbers_rounded,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                validator: AppValidators.nin,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        );

      case KycStep.document:
        return _StepContent(
          icon: Icons.document_scanner_rounded,
          title: 'Upload ID document',
          subtitle:
              'Upload a clear photo of a valid government ID (National ID, Voter\'s card, Driver\'s licence, or International passport).',
          child: Column(
            children: [
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _pickDocument,
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: _idDocument != null
                        ? AppColors.success50
                        : (context.isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.lightSurfaceVariant),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusLG),
                    border: Border.all(
                      color: _idDocument != null
                          ? AppColors.success300
                          : AppColors.neutral300,
                      style: BorderStyle.solid,
                      width: 1.5,
                    ),
                  ),
                  child: _idDocument != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.success600, size: 40),
                            const SizedBox(height: 8),
                            Text(_idDocument!.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            const Text('Tap to change',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.neutral500)),
                          ],
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.upload_file_rounded,
                                color: AppColors.neutral400, size: 40),
                            SizedBox(height: 8),
                            Text('Tap to upload document',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.neutral600)),
                            Text('JPG, PNG, or PDF',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.neutral400)),
                          ],
                        ),
                ),
              ),
            ],
          ),
        );

      case KycStep.selfie:
        return _StepContent(
          icon: Icons.camera_alt_rounded,
          title: 'Take a selfie',
          subtitle:
              'Take a clear selfie showing your face. Make sure you\'re in a well-lit area.',
          child: Column(
            children: [
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _captureSelfie,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: _selfie != null
                        ? AppColors.success50
                        : (context.isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.lightSurfaceVariant),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusLG),
                    border: Border.all(
                      color: _selfie != null
                          ? AppColors.success300
                          : AppColors.neutral300,
                      width: 1.5,
                    ),
                  ),
                  child: _selfie != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.success600, size: 40),
                            const SizedBox(height: 8),
                            const Text('Selfie captured',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            const Text('Tap to retake',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.neutral500)),
                          ],
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_rounded,
                                color: AppColors.neutral400, size: 48),
                            SizedBox(height: 8),
                            Text('Tap to open camera',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.neutral600)),
                          ],
                        ),
                ),
              ),
            ],
          ),
        );

      case KycStep.complete:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: AppColors.success50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_rounded,
                    color: AppColors.success600, size: 48),
              ),
              const SizedBox(height: 24),
              Text('Verification submitted',
                  style: context.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                'Your documents are under review. This typically takes 24-48 hours. You\'ll be notified once verified.',
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.neutral500),
              ),
              const SizedBox(height: 32),
              KDButton(
                label: 'Done',
                onPressed: () => Navigator.of(context).pop(),
                gradient: AppColors.primaryGradient,
              ),
            ],
          ),
        );
    }
  }
}

class _StepContent extends StatelessWidget {
  const _StepContent({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.primary50,
            borderRadius: BorderRadius.circular(16),
          ),
          child:
              Icon(icon, color: context.colors.primary, size: 28),
        ),
        const SizedBox(height: 16),
        Text(title,
            style: context.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(subtitle,
            style: context.textTheme.bodyMedium
                ?.copyWith(color: AppColors.neutral500)),
        child,
        const SizedBox(height: 24),
      ],
    );
  }
}
