import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/config/app_endpoints.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/kd_button.dart';
import '../../../../shared/widgets/kd_text_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  bool _isLoading = false;
  XFile? _newPhoto;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (photo != null) setState(() => _newPhoto = photo);
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    context.hideKeyboard();
    setState(() => _isLoading = true);

    final dio = ref.read(dioClientProvider);

    try {
      // Upload photo first if changed
      if (_newPhoto != null) {
        final bytes = await _newPhoto!.readAsBytes();
        final formData = FormData.fromMap({
          'photo': MultipartFile.fromBytes(
            bytes,
            filename: _newPhoto!.name,
          ),
        });
        await dio.post(AppEndpoints.updatePhoto, data: formData);
      }

      // Update profile fields
      await dio.post(AppEndpoints.updateProfile, data: {
        'full_name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
      });

      // Refresh user in auth provider
      await ref.read(authNotifierProvider.notifier).refreshUser();

      if (mounted) {
        context.showSnackBar(AppStrings.profileUpdated);
        context.pop();
      }
    } on DioException catch (e) {
      if (mounted) {
        context.showSnackBar(
          e.response?.data?['message']?.toString() ??
              AppStrings.somethingWentWrong,
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.editProfile),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleSave,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    AppStrings.save,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: context.colors.primary,
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 12),

                // ── Avatar picker ──────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: _pickPhoto,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 52,
                          backgroundColor: AppColors.primary100,
                          backgroundImage: _newPhoto != null
                              ? null
                              : (user?.photoUrl != null
                                  ? CachedNetworkImageProvider(
                                      user!.photoUrl!)
                                  : null),
                          child: _newPhoto == null && user?.photoUrl == null
                              ? Text(
                                  user?.initials ?? 'KD',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary700,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: context.colors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: context.colors.surface,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                Text(
                  'Tap to change photo',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: AppColors.neutral500,
                  ),
                ),

                const SizedBox(height: 32),

                // ── Fields ─────────────────────────────────
                KDTextField(
                  controller: _nameController,
                  label: AppStrings.fullNameLabel,
                  prefixIcon: Icons.person_outline_rounded,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  validator: AppValidators.fullName,
                ),

                const SizedBox(height: 16),

                KDTextField(
                  controller: _emailController,
                  label: AppStrings.emailLabel,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  validator: AppValidators.email,
                ),

                const SizedBox(height: 16),

                KDPhoneField(
                  controller: _phoneController,
                  validator: AppValidators.phone,
                ),

                const SizedBox(height: 40),

                KDButton(
                  label: AppStrings.save,
                  onPressed: _handleSave,
                  isLoading: _isLoading,
                  gradient: AppColors.primaryGradient,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
