import bcrypt from 'bcryptjs';
import { Router } from 'express';
import { nanoid } from 'nanoid';
import { z } from 'zod';
import { prisma } from '../lib/prisma.js';
import { koboToNaira } from '../lib/money.js';
import { authTokensFor, verifyAuthToken } from '../lib/auth-token.js';
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
  const tokens = authTokensFor({ id: user.id, email: user.email });
  return {
    status: true,
    data: {
      access_token: tokens.accessToken,
      refresh_token: tokens.refreshToken,
      expires_in: tokens.expiresIn,
      requires_pin_setup: !user.pinHash,
      user: publicUser(user)
    }
  };
}

authRoutes.post('/register', async (req, res) => {
  const body = z.object({
    full_name: z.string().trim().min(2),
    email: z.string().trim().email().transform((value) => value.toLowerCase()),
    phone: z.string().trim().min(6),
    password: z.string().min(8),
    referral_code: z.string().trim().optional()
  }).parse(req.body);

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

  res.status(201).json(authResponse(user));
});

authRoutes.post('/login', async (req, res) => {
  const body = z.object({
    identifier: z.string().trim().min(3),
    password: z.string().min(1)
  }).parse(req.body);

  const user = await prisma.user.findFirst({
    where: { OR: [{ email: body.identifier.toLowerCase() }, { phone: body.identifier }] }
  });
  if (!user?.passwordHash) {
    throw new ApiError(401, 'Invalid email/phone or password', 'INVALID_CREDENTIALS');
  }

  const ok = await bcrypt.compare(body.password, user.passwordHash);
  if (!ok) {
    throw new ApiError(401, 'Invalid email/phone or password', 'INVALID_CREDENTIALS');
  }

  res.json(authResponse(user));
});

authRoutes.post('/token/refresh', async (req, res) => {
  const body = z.object({ refresh_token: z.string().min(1) }).parse(req.body);
  const payload = verifyAuthToken(body.refresh_token, 'refresh');
  const user = await prisma.user.findUniqueOrThrow({ where: { id: payload.sub } });
  res.json(authResponse(user));
});

authRoutes.post('/logout', (_req, res) => {
  res.json({ status: true, message: 'Logged out' });
});
