import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Login with email/phone + password
  Future<Either<Failure, UserEntity>> login({
    required String identifier, // email or phone
    required String password,
    bool rememberMe = false,
  });

  /// Register a new account
  Future<Either<Failure, void>> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String? referralCode,
  });

  /// Send OTP to phone or email
  Future<Either<Failure, void>> sendOtp({
    required String destination,
    required String purpose, // 'register' | 'login' | 'reset_password'
  });

  /// Verify OTP code
  Future<Either<Failure, UserEntity>> verifyOtp({
    required String destination,
    required String otp,
    required String purpose,
  });

  /// Forgot password — send reset link/code
  Future<Either<Failure, void>> forgotPassword({required String email});

  /// Reset password with token
  Future<Either<Failure, void>> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  });

  /// Get currently cached/authenticated user
  Future<Either<Failure, UserEntity>> getCurrentUser({bool forceRefresh = false});

  /// Check if user has a valid session
  Future<bool> hasValidSession();

  /// Logout — clear tokens and cache
  Future<Either<Failure, void>> logout();

  /// Biometric login (re-authenticate with stored token after biometric check)
  Future<Either<Failure, UserEntity>> biometricLogin();

  /// Set transaction PIN (first time)
  Future<Either<Failure, void>> setTransactionPin({required String pin});

  /// Verify transaction PIN before sensitive operations
  Future<Either<Failure, bool>> verifyTransactionPin({required String pin});

  /// Change transaction PIN
  Future<Either<Failure, void>> changeTransactionPin({
    required String oldPin,
    required String newPin,
  });

  /// Change account password
  Future<Either<Failure, void>> changePassword({
    required String oldPassword,
    required String newPassword,
  });
}
