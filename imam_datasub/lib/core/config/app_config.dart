/// Application configuration
/// Supports development, staging, and production environments
class AppConfig {
  AppConfig._();

  // â”€â”€ Environment â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const _env = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static bool get isDevelopment => _env == 'development';
  static bool get isStaging => _env == 'staging';
  static bool get isProduction => _env == 'production';
  static bool get isDebug => isDevelopment || isStaging;

  // â”€â”€ App Info â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String appName = 'IMAM DATASUB';
  static const String packageName = 'com.imamdatasub.app';
  static const String appVersion = '1.0.0';
  static const int buildNumber = 1;

  // â”€â”€ API Config â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String _definedApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_definedApiBaseUrl.isNotEmpty) return _definedApiBaseUrl;

    switch (_env) {
      case 'development':
        return 'http://10.0.2.2:8787/api';
      case 'staging':
        return 'https://staging.imamdatasub.ng/api';
      default:
        return 'https://imamdatasubweb-production-4f62.up.railway.app/api';
    }
  }

  // â”€â”€ Timeouts â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // â”€â”€ Retry â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // â”€â”€ Token â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const Duration tokenRefreshBuffer = Duration(minutes: 5);

  // â”€â”€ Cache TTL â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const Duration dataPlansCache = Duration(minutes: 15);
  static const Duration walletBalanceCache = Duration(seconds: 30);
  static const Duration profileCache = Duration(minutes: 60);

  // â”€â”€ Pagination â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const int transactionPageSize = 20;
  static const int smsContactPageSize = 50;

  // â”€â”€ Security â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const int pinLength = 4;
  static const int otpLength = 6;
  static const int maxPinAttempts = 5;
  static const Duration pinLockoutDuration = Duration(minutes: 30);
  static const Duration sessionTimeout = Duration(hours: 24);

  // â”€â”€ Wallet Limits â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const double minFundAmount = 100.0;
  static const double maxFundAmount = 200000.0;
  static const double minTransferAmount = 100.0;
  static const double maxDailyTransfer = 500000.0;

  // â”€â”€ Referral â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String referralScheme = 'https://imamdatasub.com.ng/ref/';
  static const double referralCommissionRate = 0.02; // 2%
  static const double minCommissionWithdrawal = 500.0;

  // â”€â”€ Support â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String adminWhatsApp = '+2347067693590';
  static const String supportWhatsApp = '+2348035679448';
  static const String supportEmail = 'abdulmhassan02@gmail.com';
  static const String privacyPolicyUrl =
      'https://imamdatasubweb-production-4f62.up.railway.app/privacy-policy';
  static const String termsUrl =
      'https://imamdatasubweb-production-4f62.up.railway.app/terms';

  // â”€â”€ Play Integrity â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String playIntegrityCloudProjectNumber = '123456789';

  // â”€â”€ Feature Flags (overridden by Remote Config) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static bool enableBiometric = true;
  static bool enableReferral = true;
  static bool enableLiveChat = true;
  static bool enableAirtimeToCash = true;
  static bool enableBulkSms = true;
  static bool enableRechargeCard = true;

  // â”€â”€ Networks â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const List<String> supportedNetworks = [
    'MTN',
    'GLO',
    'AIRTEL',
    '9MOBILE',
  ];

  // â”€â”€ Cable TV Providers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const List<String> cableProviders = ['DSTV', 'GOTV', 'STARTIMES'];

  // â”€â”€ Electricity Providers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const List<String> electricityProviders = [
    'IKEDC',
    'EKEDC',
    'KEDCO',
    'AEDC',
    'PHEDC',
    'EEDC',
    'IBEDC',
    'KAEDCO',
    'JED',
    'BEDC',
  ];
}
