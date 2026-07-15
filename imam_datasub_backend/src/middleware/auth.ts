import type { NextFunction, Request, Response } from 'express';
import { nanoid } from 'nanoid';
import { prisma } from '../lib/prisma.js';
import { metadataString, verifySupabaseAccessToken } from '../lib/supabase-auth.js';

export type AuthUser = {
  id: string;
  email: string;
  fullName: string;
  phone: string;
};

declare global {
  namespace Express {
    interface Request {
      user?: AuthUser;
    }
  }
}

export async function requireAuth(req: Request, res: Response, next: NextFunction) {
  try {
    const header = req.header('authorization') ?? '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : '';
    if (!token) return res.status(401).json({ status: false, message: 'Missing auth token' });

    const decoded = verifySupabaseAccessToken(token);
    const metadata = decoded.user_metadata;
    const email =
      decoded.email?.trim().toLowerCase() ||
      metadataString(metadata, 'email').toLowerCase() ||
      `${decoded.sub}@supabase.local`;
    const phone =
      decoded.phone?.trim() ||
      metadataString(metadata, 'phone') ||
      metadataString(metadata, 'phone_number') ||
      `supabase-${decoded.sub}`;
    const fullName =
      metadataString(metadata, 'full_name') ||
      metadataString(metadata, 'name') ||
      email.split('@')[0] ||
      'User';

    const user = await prisma.user.upsert({
      where: { id: decoded.sub },
      update: {
        email,
        fullName,
        phone,
        emailVerified: Boolean(decoded.email_confirmed_at),
        phoneVerified: Boolean(decoded.phone_confirmed_at)
      },
      create: {
        id: decoded.sub,
        email,
        phone,
        fullName,
        emailVerified: Boolean(decoded.email_confirmed_at),
        phoneVerified: Boolean(decoded.phone_confirmed_at),
        referralCode: nanoid(8).toUpperCase()
      }
    });

    req.user = {
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      phone: user.phone
    };
    next();
  } catch (error) {
    next(error);
  }
}
