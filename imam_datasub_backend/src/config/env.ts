import 'dotenv/config';
import { z } from 'zod';

const EnvSchema = z.object({
  NODE_ENV: z.string().default('development'),
  PORT: z.coerce.number().default(8787),
  DATABASE_URL: z.string().min(1),
  DIRECT_URL: z.string().optional(),
  AUTH_TOKEN_SECRET: z.string().min(32).default('dev-only-insecure-auth-token-secret-change-me'),
  ACCESS_TOKEN_TTL_SECONDS: z.coerce.number().int().positive().default(60 * 60 * 24),
  REFRESH_TOKEN_TTL_SECONDS: z.coerce.number().int().positive().default(60 * 60 * 24 * 30),
  FIREBASE_SERVICE_ACCOUNT_BASE64: z.string().optional(),
  ALRAHUZ_BASE_URL: z.string().url().default('https://alrahuzdata.com.ng/api'),
  ALRAHUZ_API_TOKEN: z.string().optional(),
  MOCK_PROVIDER: z.coerce.boolean().default(true),
  PAYSTACK_SECRET_KEY: z.string().optional(),
  PAYSTACK_CALLBACK_URL: z.string().url().optional(),
  ADMIN_SESSION_SECRET: z.string().min(16).default('dev-only-insecure-admin-secret-change-me')
});

export const env = EnvSchema.parse(process.env);

if (env.NODE_ENV === 'production' && env.ADMIN_SESSION_SECRET === 'dev-only-insecure-admin-secret-change-me') {
  throw new Error(
    'ADMIN_SESSION_SECRET is still the default dev value. Set a strong random secret before running in production.'
  );
}

if (env.NODE_ENV === 'production' && env.AUTH_TOKEN_SECRET === 'dev-only-insecure-auth-token-secret-change-me') {
  throw new Error(
    'AUTH_TOKEN_SECRET is still the default dev value. Set a strong random secret before running in production.'
  );
}
