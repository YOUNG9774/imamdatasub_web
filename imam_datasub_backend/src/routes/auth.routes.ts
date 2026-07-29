import bcrypt from 'bcryptjs';
import { Router } from 'express';
import { nanoid } from 'nanoid';
import { z } from 'zod';
import { issueAuthTokens, revokeRefreshToken, rotateRefreshToken } from '../lib/auth-token.js';
import { koboToNaira } from '../lib/money.js';
import { prisma } from '../lib/prisma.js';
import { requireAuth } from '../middleware/auth.js';
import { ApiError } from '../middleware/error.js';
import { verifyLoginPin } from '../services/login-pin.service.js';
import { tryProvisionInstantVirtualAccount } from '../services/kyc.service.js';

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

async function authResponse(
  user: Awaited<ReturnType<typeof prisma.user.findUniqueOrThrow>>,
  tokens: { accessToken: string; refreshToken: string; expiresIn: number }
) {
  return {
    status: true,
    data: {
      access_token: tokens.accessToken,
      refresh_token: tokens.refreshToken,
      expires_in: tokens.expiresIn,
      requires_pin_setup: !user.pinHash,
      requires_login_pin_setup: !user.loginPinHash,
      user: publicUser(user)
    }
  };
}

authRoutes.post('/register', async (req, res) => {
  const body = z
    .object({
      full_name: z.string().trim().min(2),
      email: z
        .string()
        .trim()
        .email()
        .transform((value) => value.toLowerCase()),
      phone: z.string().trim().min(6),
      password: z.string().min(8),
      referral_code: z.string().trim().optional()
    })
    .parse(req.body);

  const existing = await prisma.user.findFirst({
    where: { OR: [{ email: body.email }, { phone: body.phone }] }
  });
  if (existing) {
    throw new ApiError(409, 'An account already exists with this email or phone', 'ACCOUNT_EXISTS');
  }

  const passwordHash = await bcrypt.hash(body.password, 12);
  const user = await prisma.user.create({
    data: {
      id: nanoid(),
      fullName: body.full_name,
      email: body.email,
      phone: body.phone,
      passwordHash,
      referredByCode: body.referral_code,
      referralCode: nanoid(8).toUpperCase(),
      emailVerified: false,
      phoneVerified: false
    }
  });

  // Best-effort - see tryProvisionInstantVirtualAccount for why this never
  // throws. Re-fetch afterwards so the register response (and the dashboard
  // the app shows immediately after) already includes the account number.
  await tryProvisionInstantVirtualAccount(user.id);
  const provisionedUser = await prisma.user.findUniqueOrThrow({ where: { id: user.id } });

  const tokens = await issueAuthTokens({ id: provisionedUser.id, email: provisionedUser.email });
  res.status(201).json(await authResponse(provisionedUser, tokens));
});

authRoutes.post('/login', async (req, res) => {
  const body = z
    .object({
      identifier: z.string().trim().min(3),
      password: z.string().min(1),
      // Only required once the account already has a login PIN set - see below.
      login_pin: z.string().optional()
    })
    .parse(req.body);

  const user = await prisma.user.findFirst({
    where: { OR: [{ email: body.identifier.toLowerCase() }, { phone: body.identifier }] }
  });
  if (!user) {
    throw new ApiError(401, 'Invalid email/phone or password', 'INVALID_CREDENTIALS');
  }

  if (!user.passwordHash) {
    throw new ApiError(401, 'Invalid email/phone or password', 'INVALID_CREDENTIALS');
  }

  const ok = await bcrypt.compare(body.password, user.passwordHash);
  if (!ok) {
    throw new ApiError(401, 'Invalid email/phone or password', 'INVALID_CREDENTIALS');
  }

  if (user.accountStatus === 'DEACTIVATED') {
    throw new ApiError(
      403,
      'Your account is deactivated. Contact support to reactivate it.',
      'ACCOUNT_DEACTIVATED'
    );
  }

  // Once a login PIN exists on the account, every call to /auth/login (i.e.
  // every login from a device that isn't already holding a valid session)
  // must also supply it - this is what makes "login on another device" ask
  // for password AND PIN. A trusted device with a live session never calls
  // this route again; it unlocks locally with the same PIN instead.
  if (user.loginPinHash) {
    if (!body.login_pin) {
      throw new ApiError(401, 'Enter your 6-digit login PIN to continue', 'LOGIN_PIN_REQUIRED');
    }
    // Propagates LOGIN_PIN_LOCKED / INVALID_LOGIN_PIN as-is on failure.
    await verifyLoginPin(user.id, body.login_pin);
  }

  const tokens = await issueAuthTokens({ id: user.id, email: user.email });
  res.json(await authResponse(user, tokens));
});

authRoutes.post('/token/refresh', async (req, res) => {
  const body = z.object({ refresh_token: z.string().min(1) }).parse(req.body);
  const { user, tokens } = await rotateRefreshToken(body.refresh_token);
  res.json(await authResponse(user, tokens));
});

authRoutes.post('/logout', async (req, res) => {
  const body = z.object({ refresh_token: z.string().min(1) }).parse(req.body);
  await revokeRefreshToken(body.refresh_token);
  res.json({ status: true, message: 'Logged out' });
});

authRoutes.get('/me', requireAuth, async (req, res) => {
  const user = await prisma.user.findUniqueOrThrow({ where: { id: req.user!.id } });
  res.json({
    status: true,
    data: {
      requires_pin_setup: !user.pinHash,
      requires_login_pin_setup: !user.loginPinHash,
      user: publicUser(user)
    }
  });
});
