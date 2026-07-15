import { Router } from 'express';
import { prisma } from '../lib/prisma.js';
import { koboToNaira } from '../lib/money.js';
import { requireAuth } from '../middleware/auth.js';
import { ApiError } from '../middleware/error.js';

export const authRoutes = Router();

function publicUser(user: Awaited<ReturnType<typeof prisma.user.findUniqueOrThrow>>) {
  return {
    id: user.id,
    full_name: user.fullName,
    email: user.email,
    phone: user.phone,
    photo_url: user.photoUrl,
    wallet_balance: koboToNaira(user.walletBalanceKobo),
    referral_code: user.referralCode,
    referral_earnings: koboToNaira(user.referralEarningsKobo),
    kyc_status: user.kycStatus.toLowerCase(),
    email_verified: user.emailVerified,
    phone_verified: user.phoneVerified,
    virtual_account_number: user.virtualAccountNumber,
    virtual_account_bank: user.virtualAccountBank,
    created_at: user.createdAt.toISOString()
  };
}

function authResponse(user: Awaited<ReturnType<typeof prisma.user.findUniqueOrThrow>>) {
  return {
    status: true,
    data: {
      requires_pin_setup: !user.pinHash,
      user: publicUser(user)
    }
  };
}

authRoutes.post('/register', () => {
  throw new ApiError(410, 'Use Supabase Auth signUp from Flutter, then call /api/auth/sync', 'USE_SUPABASE_AUTH');
});

authRoutes.post('/login', () => {
  throw new ApiError(
    410,
    'Use Supabase Auth signInWithPassword from Flutter, then call /api/auth/sync',
    'USE_SUPABASE_AUTH'
  );
});

authRoutes.use(requireAuth);

authRoutes.post('/sync', async (req, res) => {
  const user = await prisma.user.findUniqueOrThrow({ where: { id: req.user!.id } });
  res.json(authResponse(user));
});

authRoutes.get('/me', async (req, res) => {
  const user = await prisma.user.findUniqueOrThrow({ where: { id: req.user!.id } });
  res.json(authResponse(user));
});

authRoutes.post('/logout', (_req, res) => {
  res.json({
    status: true,
    message: 'Logout is handled by Supabase on the client. Backend session cleared.'
  });
});
