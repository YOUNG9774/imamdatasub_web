import type { NextFunction, Request, Response } from 'express';
import { nanoid } from 'nanoid';
import { verifyAuthToken } from '../lib/auth-token.js';
import { getFirebaseAdmin } from '../lib/firebase.js';
import { prisma } from '../lib/prisma.js';

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

    try {
      const payload = verifyAuthToken(token, 'access');
      const user = await prisma.user.findUniqueOrThrow({ where: { id: payload.sub } });
      req.user = {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        phone: user.phone
      };
      return next();
    } catch {
      // Fall through to Firebase verification for older app builds that still send Firebase ID tokens.
    }

    const decoded = await getFirebaseAdmin().auth().verifyIdToken(token);
    const email = decoded.email ?? '';
    const phone = decoded.phone_number ?? '';
    const fullName = decoded.name ?? email.split('@')[0] ?? 'User';

    const user = await prisma.user.upsert({
      where: { id: decoded.uid },
      update: {
        email,
        fullName,
        emailVerified: decoded.email_verified ?? false
      },
      create: {
        id: decoded.uid,
        email,
        phone: phone || `firebase-${decoded.uid}`,
        fullName,
        emailVerified: decoded.email_verified ?? false,
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
