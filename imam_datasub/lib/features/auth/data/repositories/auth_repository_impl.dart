import 'package:dartz/dartz.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
    required NetworkInfo networkInfo,
  }) : _remote = remote,
       _local = local,
       _networkInfo = networkInfo;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;
  final NetworkInfo _networkInfo;

  @override
  Future<Either<Failure, UserEntity>> login({
    required String identifier,
    required String password,
    bool rememberMe = false,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final response = await _remote.login(
        identifier: identifier,
        password: password,
      );
      await _local.cacheAuthResponse(response);

      if (rememberMe) {
        await _local.saveRememberedIdentifier(identifier);
      }

      return Right(response.user);
    } on AppException catch (e) {
      return Left(ErrorHandler.exceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String? referralCode,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final response = await _remote.register(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
        referralCode: referralCode,
      );
      await _local.cacheAuthResponse(response);
      return const Right(null);
    } on AppException catch (e) {
      return Left(ErrorHandler.exceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendOtp({
    required String destination,
    required String purpose,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await _remote.sendOtp(destination: destination, purpose: purpose);
      return const Right(null);
    } on AppException catch (e) {
      return Left(ErrorHandler.exceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> verifyOtp({
    required String destination,
    required String otp,
    required String purpose,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final response = await _remote.verifyOtp(
        destination: destination,
        otp: otp,
        purpose: purpose,
      );
      if (response.accessToken.isNotEmpty) {
        await _local.cacheAuthResponse(response);
      }
      return Right(response.user);
    } on AppException catch (e) {
      return Left(ErrorHandler.exceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> forgotPassword({required String email}) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await _remote.forgotPassword(email: email);
      return const Right(null);
    } on AppException catch (e) {
      return Left(ErrorHandler.exceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await _remote.resetPassword(
        email: email,
        token: token,
        newPassword: newPassword,
      );
      return const Right(null);
    } on AppException catch (e) {
      return Left(ErrorHandler.exceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser({
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh) {
        final cached = await _local.getCachedUser();
        if (cached != null) return Right(cached);
      }

      if (!await _networkInfo.isConnected) {
        final cached = await _local.getCachedUser();
        if (cached != null) return Right(cached);
        return const Left(NetworkFailure());
      }

      final profile = await _remote.getProfile();
      await _local.cacheUser(profile);
      return Right(profile);
    } on AppException catch (e) {
      return Left(ErrorHandler.exceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<bool> hasValidSession() => _local.hasValidSession();

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      if (await _networkInfo.isConnected) {
        await _remote.logout();
      }
      await _local.clearSession();
      return const Right(null);
    } catch (e) {
      // Always clear local session even if remote call fails
      await _local.clearSession();
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, UserEntity>> biometricLogin() async {
    try {
      final hasSession = await _local.hasValidSession();
      if (!hasSession) {
        return const Left(AuthFailure.sessionExpired());
      }
      final cached = await _local.getCachedUser();
      if (cached == null) {
        return const Left(AuthFailure(message: 'No cached user found'));
      }
      return Right(cached);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setTransactionPin({required String pin}) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await _remote.setPin(pin: pin);
      await _local.savePinLocally(pin);
      return const Right(null);
    } on AppException catch (e) {
      return Left(ErrorHandler.exceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyTransactionPin({
    required String pin,
  }) async {
    try {
      // Check lockout first
      if (await _local.isPinLockedOut()) {
        return const Left(PinFailure.lockedOut());
      }

      // Try local verification first (faster, works offline)
      final hasLocalPin = await _local.hasPinSet();
      if (hasLocalPin) {
        final isValid = await _local.verifyPinLocally(pin);
        if (!isValid) {
          final remaining = await _local.getRemainingPinAttempts();
          if (remaining <= 0) {
            return const Left(PinFailure.lockedOut());
          }
          return Left(PinFailure.wrong(attemptsLeft: remaining));
        }
        return const Right(true);
      }

      // Fallback to remote verification
      if (!await _networkInfo.isConnected) {
        return const Left(NetworkFailure());
      }
      final isValid = await _remote.verifyPin(pin: pin);
      return Right(isValid);
    } on AppException catch (e) {
      return Left(ErrorHandler.exceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> changeTransactionPin({
    required String oldPin,
    required String newPin,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await _remote.changePin(oldPin: oldPin, newPin: newPin);
      await _local.savePinLocally(newPin);
      return const Right(null);
    } on AppException catch (e) {
      return Left(ErrorHandler.exceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await _remote.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      return const Right(null);
    } on AppException catch (e) {
      return Left(ErrorHandler.exceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
