import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../lib/prisma.js';
import { koboToNaira } from '../lib/money.js';
import { requireAuth } from '../middleware/auth.js';
import { setPin, verifyPin } from '../services/wallet.service.js';

export const userRoutes = Router();

userRoutes.use(requireAuth);

userRoutes.get('/profile', async (req, res) => {
  const user = await prisma.user.findUniqueOrThrow({ where: { id: req.user!.id } });
  res.json({
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
  });
});

userRoutes.post('/pin/set', async (req, res) => {
  const body = z.object({ pin: z.string() }).parse(req.body);
  await setPin(req.user!.id, body.pin);
  res.json({ status: true, message: 'PIN set successfully' });
});

userRoutes.post('/pin/verify', async (req, res) => {
  const body = z.object({ pin: z.string() }).parse(req.body);
  await verifyPin(req.user!.id, body.pin);
  res.json({ status: true, data: { valid: true } });
});
