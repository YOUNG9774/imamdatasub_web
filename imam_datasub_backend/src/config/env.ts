import 'dotenv/config';
import { z } from 'zod';

const EnvSchema = z.object({
  NODE_ENV: z.string().default('development'),
  PORT: z.coerce.number().default(8787),
  DATABASE_URL: z.string().min(1, 'DATABASE_URL is required'),
  DIRECT_URL: z.string().optional(),
  FIREBASE_SERVICE_ACCOUNT_BASE64: z.string().optional(),
  ALRAHUZ_BASE_URL: z.string().url().default('https://alrahuzdata.com.ng/api'),
  ALRAHUZ_API_TOKEN: z.string().optional(),
  ALRAHUZ_DATA_PLANS_PATH: z.string().default('/data/'),
  ALRAHUZ_DATA_PLANS_CACHE_SECONDS: z.coerce.number().int().positive().default(900),
  DATA_PLAN_MARKUP_PERCENT: z.coerce.number().min(0).default(0),
  DATA_PLAN_MARKUP_NAIRA: z.coerce.number().min(0).default(0),
  AUTH_TOKEN_SECRET: z.string().min(32).default('dev-only-insecure-auth-token-secret-32'),
  ACCESS_TOKEN_TTL_SECONDS: z.coerce.number().int().positive().default(86_400),
  REFRESH_TOKEN_TTL_SECONDS: z.coerce.number().int().positive().default(2_592_000),
  // NOTE: z.coerce.boolean() would parse the STRING "false" as true (JS's
  // Boolean("false") === true — any non-empty string is truthy). This explicit
  // string comparison is what actually respects MOCK_PROVIDER=false in .env.
  MOCK_PROVIDER: z
    .string()
    .default('true')
    .transform((value) => value.toLowerCase() !== 'false' && value !== '0'),
  PAYSTACK_SECRET_KEY: z.string().optional(),
  PAYSTACK_CALLBACK_URL: z.string().url().optional(),
  ADMIN_SESSION_SECRET: z.string().min(16).default('dev-only-insecure-admin-secret-change-me'),
  SUPABASE_JWT_SECRET: z.string().optional()
});

// Parse environment variables with enhanced error handling
let env: z.infer<typeof EnvSchema>;

try {
  env = EnvSchema.parse(process.env);
} catch (error) {
  if (error instanceof z.ZodError) {
    console.error('✗ Environment variable validation failed:');
    error.errors.forEach((err) => {
      const path = err.path.join('.');
      console.error(`  - ${path}: ${err.message}`);
    });
    console.error('\n✗ Please check your .env file or environment variables');
    process.exit(1);
  }
  throw error;
}

// Production security checks
if (env.NODE_ENV === 'production') {
  const securityIssues: string[] = [];

  if (env.ADMIN_SESSION_SECRET === 'dev-only-insecure-admin-secret-change-me') {
    securityIssues.push('ADMIN_SESSION_SECRET is still the default dev value');
  }

  if (env.AUTH_TOKEN_SECRET === 'dev-only-insecure-auth-token-secret-32') {
    securityIssues.push('AUTH_TOKEN_SECRET is still the default dev value');
  }

  if (securityIssues.length > 0) {
    console.error('✗ Production security violations detected:');
    securityIssues.forEach((issue) => {
      console.error(`  - ${issue}`);
    });
    console.error('\n✗ Set strong random secrets before running in production');
    process.exit(1);
  }

  console.log('✓ All production security checks passed');
}

export { env };
