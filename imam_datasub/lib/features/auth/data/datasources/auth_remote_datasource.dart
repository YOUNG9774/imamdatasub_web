import 'package:dio/dio.dart';

import '../../../../core/config/app_endpoints.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/exceptions.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login({
    required String identifier,
    required String password,
  });

  Future<AuthResponseModel> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String? referralCode,
  });

  Future<void> sendOtp({required String destination, required String purpose});

  Future<AuthResponseModel> verifyOtp({
    required String destination,
    required String otp,
    required String purpose,
  });

  Future<void> forgotPassword({required String email});

  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  });

  Future<UserModel> getProfile();

  Future<void> logout();

  Future<void> setPin({required String pin});

  Future<bool> verifyPin({required String pin});

  Future<void> changePin({required String oldPin, required String newPin});

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<AuthResponseModel> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        AppEndpoints.login,
        data: {'identifier': identifier.trim(), 'password': password},
      );
      return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  @override
  Future<AuthResponseModel> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String? referralCode,
  }) async {
    try {
      final response = await _dio.post(
        AppEndpoints.register,
        data: {
          'full_name': fullName.trim(),
          'email': email.trim(),
          'phone': phone.trim(),
          'password': password,
          if (referralCode != null && referralCode.trim().isNotEmpty)
            'referral_code': referralCode.trim(),
        },
      );
      return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  @override
  Future<void> sendOtp({
    required String destination,
    required String purpose,
  }) async {
    throw const AuthException(
      message: 'OTP is not enabled in the MVP login flow.',
      code: 'OTP_DISABLED',
    );
  }

  @override
  Future<AuthResponseModel> verifyOtp({
    required String destination,
    required String otp,
    required String purpose,
  }) async {
    throw const AuthException(
      message: 'OTP is not enabled in the MVP login flow.',
      code: 'OTP_DISABLED',
    );
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    throw const AuthException(
      message: 'Password reset will be added after MVP launch.',
      code: 'PASSWORD_RESET_DISABLED',
    );
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    throw const AuthException(
      message: 'Password reset will be added after MVP launch.',
      code: 'PASSWORD_RESET_DISABLED',
    );
  }

  @override
  Future<UserModel> getProfile() async {
    try {
      final response = await _dio.get(AppEndpoints.userProfile);
      final data = response.data as Map<String, dynamic>;
      return UserModel.fromJson(
        (data['data'] as Map<String, dynamic>?) ?? data,
      );
    } on DioException catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post(AppEndpoints.logout);
    } on DioException catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  @override
  Future<void> setPin({required String pin}) async {
    try {
      await _dio.post(AppEndpoints.setPin, data: {'pin': pin});
    } on DioException catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  @override
  Future<bool> verifyPin({required String pin}) async {
    try {
      final response = await _dio.post(
        AppEndpoints.verifyPin,
        data: {'pin': pin},
      );
      final data = response.data as Map<String, dynamic>;
      final nested = data['data'];
      if (nested is Map<String, dynamic> && nested['valid'] == true) {
        return true;
      }
      return data['status'] == true;
    } on DioException catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  @override
  Future<void> changePin({
    required String oldPin,
    required String newPin,
  }) async {
    try {
      await _dio.post(
        AppEndpoints.changePin,
        data: {'old_pin': oldPin, 'new_pin': newPin},
      );
    } on DioException catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  @override
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    throw const AuthException(
      message: 'Password change will be added after MVP launch.',
      code: 'PASSWORD_CHANGE_DISABLED',
    );
  }
}
