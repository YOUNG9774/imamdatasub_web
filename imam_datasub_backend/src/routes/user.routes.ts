import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../lib/prisma.js';
import { koboToNaira } from '../lib/money.js';
import { requireAuth } from '../middleware/auth.js';
import { ApiError } from '../middleware/error.js';
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

userRoutes.post('/profile/sync', async (req, res) => {
  const body = z
    .object({
      full_name: z.string().trim().min(2),
      email: z
        .string()
        .trim()
        .email()
        .transform((value) => value.toLowerCase()),
      phone: z.string().trim().min(6)
    })
    .parse(req.body);

  const conflict = await prisma.user.findFirst({
    where: {
      id: { not: req.user!.id },
      OR: [{ email: body.email }, { phone: body.phone }]
    }
  });
  if (conflict) {
    throw new ApiError(409, 'That email or phone is already in use by another account', 'PROFILE_CONFLICT');
  }

  const user = await prisma.user.update({
    where: { id: req.user!.id },
    data: {
      fullName: body.full_name,
      email: body.email,
      phone: body.phone,
      // Changing the contact detail invalidates the previous verification —
      // a real verification flow (email link / SMS OTP) should re-confirm it,
      // not carry the old verified=true forward.
      emailVerified: body.email === req.user!.email ? undefined : false,
      phoneVerified: body.phone === req.user!.phone ? undefined : false
    }
  });

  res.json({
    status: true,
    message: 'Profile updated',
    data: {
      id: user.id,
      full_name: user.fullName,
      email: user.email,
      phone: user.phone,
      email_verified: user.emailVerified,
      phone_verified: user.phoneVerified
    }
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

userRoutes.post('/pin/change', async (req, res) => {
  const body = z
    .object({
      old_pin: z.string(),
      new_pin: z.string()
    })
    .parse(req.body);

  // Re-uses the same verification path as /pin/verify, including its lockout logic —
  // a PIN change attempt with the wrong old PIN counts as a failed attempt too.
  await verifyPin(req.user!.id, body.old_pin);
  await setPin(req.user!.id, body.new_pin);
  res.json({ status: true, message: 'PIN changed successfully' });
});
