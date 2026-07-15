abstract class RouteNames {
  RouteNames._();

  // ── Shell / Root ──────────────────────────────────────────
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const shell = '/home'; // ShellRoute wrapper

  // ── Auth ──────────────────────────────────────────────────
  static const login = '/login';
  static const register = '/register';
  static const verifyOtp = '/verify-otp';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';

  // ── Main tabs ─────────────────────────────────────────────
  static const home = '/home/dashboard';
  static const services = '/home/services';
  static const transactions = '/home/transactions';
  static const referrals = '/home/referrals';
  static const profile = '/home/profile';

  // ── Services ──────────────────────────────────────────────
  static const buyData = '/home/services/data';
  static const buyAirtime = '/home/services/airtime';
  static const airtimeToCash = '/home/services/airtime-to-cash';
  static const cableTv = '/home/services/cable';
  static const electricity = '/home/services/electricity';
  static const waecChecker = '/home/services/waec';
  static const necoChecker = '/home/services/neco';
  static const nabtebChecker = '/home/services/nabteb';
  static const jambServices = '/home/services/jamb';
  static const bulkSms = '/home/services/bulk-sms';
  static const rechargeCard = '/home/services/recharge-card';
  static const dataCard = '/home/services/data-card';

  // ── Wallet ────────────────────────────────────────────────
  static const wallet = '/home/dashboard/wallet';
  static const fundWallet = '/home/dashboard/wallet/fund';
  static const walletTransfer = '/home/dashboard/wallet/transfer';
  static const virtualAccount = '/home/dashboard/wallet/virtual-account';

  // ── Transaction detail ────────────────────────────────────
  static const transactionDetail = '/home/transactions/:id';

  // ── Purchase success ──────────────────────────────────────
  static const purchaseSuccess = '/purchase-success';

  // ── KYC ───────────────────────────────────────────────────
  static const kyc = '/home/profile/kyc';
  static const kycBvn = '/home/profile/kyc/bvn';
  static const kycNin = '/home/profile/kyc/nin';
  static const kycDocument = '/home/profile/kyc/document';

  // ── Profile sub-routes ────────────────────────────────────
  static const editProfile = '/home/profile/edit';
  static const changePassword = '/home/profile/password';
  static const changePin = '/home/profile/pin';
  static const security = '/home/profile/security';

  // ── Settings ──────────────────────────────────────────────
  static const settings = '/home/profile/settings';

  // Admin
  static const adminDataPricing = '/home/profile/admin/data-pricing';

  // ── Notifications ─────────────────────────────────────────
  static const notifications = '/home/dashboard/notifications';

  // ── Support ───────────────────────────────────────────────
  static const support = '/home/profile/support';
  static const liveChat = '/home/profile/support/chat';
  static const tickets = '/home/profile/support/tickets';
  static const newTicket = '/home/profile/support/tickets/new';
  static const ticketDetail = '/home/profile/support/tickets/:id';
  static const faq = '/home/profile/support/faq';

  // ── Legal ─────────────────────────────────────────────────
  static const privacyPolicy = '/privacy-policy';
  static const terms = '/terms';
}
