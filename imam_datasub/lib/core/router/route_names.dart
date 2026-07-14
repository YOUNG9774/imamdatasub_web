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
  static const wallet = '/home/wallet';
  static const fundWallet = '/home/wallet/fund';
  static const walletTransfer = '/home/wallet/transfer';
  static const virtualAccount = '/home/wallet/virtual-account';

  // ── Transaction detail ────────────────────────────────────
  static const transactionDetail = '/home/transactions/:id';

  // ── Purchase success ──────────────────────────────────────
  static const purchaseSuccess = '/purchase-success';

  // ── KYC ───────────────────────────────────────────────────
  static const kyc = '/home/kyc';
  static const kycBvn = '/home/kyc/bvn';
  static const kycNin = '/home/kyc/nin';
  static const kycDocument = '/home/kyc/document';

  // ── Profile sub-routes ────────────────────────────────────
  static const editProfile = '/home/profile/edit';
  static const changePassword = '/home/profile/password';
  static const changePin = '/home/profile/pin';
  static const security = '/home/profile/security';

  // ── Settings ──────────────────────────────────────────────
  static const settings = '/home/settings';

  // ── Notifications ─────────────────────────────────────────
  static const notifications = '/home/notifications';

  // ── Support ───────────────────────────────────────────────
  static const support = '/home/support';
  static const liveChat = '/home/support/chat';
  static const tickets = '/home/support/tickets';
  static const newTicket = '/home/support/tickets/new';
  static const ticketDetail = '/home/support/tickets/:id';
  static const faq = '/home/support/faq';

  // ── Legal ─────────────────────────────────────────────────
  static const privacyPolicy = '/privacy-policy';
  static const terms = '/terms';
}
