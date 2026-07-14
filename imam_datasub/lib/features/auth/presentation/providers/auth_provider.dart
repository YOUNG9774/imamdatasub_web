import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/router/auth_status.dart';
import '../../../../core/security/biometric_service.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';

// Ã¢â€â‚¬Ã¢â€â‚¬ Data layer providers Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(ref.read(dioClientProvider));
});

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSourceImpl(
    ref.read(secureStorageProvider),
    ref.read(hiveStorageProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remote: ref.read(authRemoteDataSourceProvider),
    local: ref.read(authLocalDataSourceProvider),
    networkInfo: ref.read(networkInfoProvider),
  );
});

// Ã¢â€â‚¬Ã¢â€â‚¬ Use case providers Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
final loginUseCaseProvider = Provider(
  (ref) => LoginUseCase(ref.read(authRepositoryProvider)),
);
final registerUseCaseProvider = Provider(
  (ref) => RegisterUseCase(ref.read(authRepositoryProvider)),
);
final sendOtpUseCaseProvider = Provider(
  (ref) => SendOtpUseCase(ref.read(authRepositoryProvider)),
);
final verifyOtpUseCaseProvider = Provider(
  (ref) => VerifyOtpUseCase(ref.read(authRepositoryProvider)),
);
final forgotPasswordUseCaseProvider = Provider(
  (ref) => ForgotPasswordUseCase(ref.read(authRepositoryProvider)),
);
final resetPasswordUseCaseProvider = Provider(
  (ref) => ResetPasswordUseCase(ref.read(authRepositoryProvider)),
);
final getCurrentUserUseCaseProvider = Provider(
  (ref) => GetCurrentUserUseCase(ref.read(authRepositoryProvider)),
);
final logoutUseCaseProvider = Provider(
  (ref) => LogoutUseCase(ref.read(authRepositoryProvider)),
);
final biometricLoginUseCaseProvider = Provider(
  (ref) => BiometricLoginUseCase(ref.read(authRepositoryProvider)),
);
final setTransactionPinUseCaseProvider = Provider(
  (ref) => SetTransactionPinUseCase(ref.read(authRepositoryProvider)),
);
final verifyTransactionPinUseCaseProvider = Provider(
  (ref) => VerifyTransactionPinUseCase(ref.read(authRepositoryProvider)),
);
final changeTransactionPinUseCaseProvider = Provider(
  (ref) => ChangeTransactionPinUseCase(ref.read(authRepositoryProvider)),
);
final changePasswordUseCaseProvider = Provider(
  (ref) => ChangePasswordUseCase(ref.read(authRepositoryProvider)),
);

// Ã¢â€â‚¬Ã¢â€â‚¬ Auth State Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
class AuthState {
  const AuthState({
    this.user,
    this.status = AuthStatus.unauthenticated,
    this.isLoading = false,
    this.errorMessage,
  });

  final UserEntity? user;
  final AuthStatus status;
  final bool isLoading;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    UserEntity? user,
    AuthStatus? status,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬ Auth Notifier Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthState()) {
    _checkSession();
  }

  final Ref _ref;

  Future<void> _checkSession() async {
    state = state.copyWith(isLoading: true);
    final repository = _ref.read(authRepositoryProvider);
    final hasSession = await repository.hasValidSession();

    if (!hasSession) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
      );
      _syncRouterAuthState();
      return;
    }

    final result = await _ref.read(getCurrentUserUseCaseProvider).call();
    result.fold(
      (failure) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoading: false,
        );
      },
      (user) {
        state = state.copyWith(
          user: user,
          status: AuthStatus.authenticated,
          isLoading: false,
        );
      },
    );
    _syncRouterAuthState();
  }

  Future<bool> login({
    required String identifier,
    required String password,
    bool rememberMe = false,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _ref
        .read(loginUseCaseProvider)
        .call(
          identifier: identifier,
          password: password,
          rememberMe: rememberMe,
        );

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (user) {
        state = state.copyWith(
          user: user,
          status: AuthStatus.authenticated,
          isLoading: false,
          clearError: true,
        );
        _syncRouterAuthState();
        return true;
      },
    );
  }

  Future<Either<Failure, void>> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String? referralCode,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _ref
        .read(registerUseCaseProvider)
        .call(
          fullName: fullName,
          email: email,
          phone: phone,
          password: password,
          referralCode: referralCode,
        );

    await result.fold<Future<void>>(
      (failure) async {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
      (_) async {
        final currentUser = await _ref
            .read(getCurrentUserUseCaseProvider)
            .call();
        currentUser.fold(
          (failure) {
            state = state.copyWith(
              isLoading: false,
              errorMessage: failure.message,
            );
          },
          (user) {
            state = state.copyWith(
              user: user,
              status: AuthStatus.authenticated,
              isLoading: false,
              clearError: true,
            );
            _syncRouterAuthState();
          },
        );
      },
    );

    return result;
  }

  Future<bool> verifyOtp({
    required String destination,
    required String otp,
    required String purpose,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _ref
        .read(verifyOtpUseCaseProvider)
        .call(destination: destination, otp: otp, purpose: purpose);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (user) {
        if (user.isNotEmpty) {
          state = state.copyWith(
            user: user,
            status: AuthStatus.authenticated,
            isLoading: false,
            clearError: true,
          );
          _syncRouterAuthState();
        } else {
          state = state.copyWith(isLoading: false, clearError: true);
        }
        return true;
      },
    );
  }

  Future<bool> sendOtp({
    required String destination,
    required String purpose,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _ref
        .read(sendOtpUseCaseProvider)
        .call(destination: destination, purpose: purpose);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(isLoading: false, clearError: true);
        return true;
      },
    );
  }

  Future<bool> tryBiometricLogin() async {
    final localDs = _ref.read(authLocalDataSourceProvider);
    final isEnabled = await localDs.isBiometricEnabled();
    if (!isEnabled) return false;

    final biometricService = _ref.read(biometricServiceProvider);
    final isAvailable = await biometricService.isAvailable();
    if (!isAvailable) return false;

    final authResult = await biometricService.authenticate(
      title: 'Unlock IMAM DATASUB',
      subtitle: 'Use your fingerprint or face to sign in',
    );

    if (authResult != BiometricResult.success) return false;

    final result = await _ref.read(biometricLoginUseCaseProvider).call();
    return result.fold((failure) => false, (user) {
      state = state.copyWith(
        user: user,
        status: AuthStatus.authenticated,
        isLoading: false,
      );
      _syncRouterAuthState();
      return true;
    });
  }

  Future<void> logout() async {
    await _ref.read(logoutUseCaseProvider).call();
    state = const AuthState(status: AuthStatus.unauthenticated);
    _syncRouterAuthState();
  }

  void clearError() => state = state.copyWith(clearError: true);

  void _syncRouterAuthState() {
    _ref.read(authStateProvider.notifier).state = AsyncValue.data(state.status);
  }

  Future<void> refreshUser() async {
    final result = await _ref
        .read(getCurrentUserUseCaseProvider)
        .call(forceRefresh: true);
    result.fold((_) {}, (user) => state = state.copyWith(user: user));
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  return AuthNotifier(ref);
});

// Convenience providers
final currentUserProvider = Provider<UserEntity?>((ref) {
  return ref.watch(authNotifierProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isAuthenticated;
});
