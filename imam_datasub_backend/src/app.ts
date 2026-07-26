// MUST be the first import in this file. It monkey-patches Express's Router
// so that a rejected promise inside an `async (req, res) => {...}` handler is
// automatically forwarded to `next(error)` -> errorHandler, instead of
// escaping as an unhandled promise rejection at the process level.
//
// Without this, Express 4.x does NOT catch errors thrown/rejected inside
// async route handlers. Combined with the `process.on('unhandledRejection', ...)`
// handler in server.ts (which calls `process.exit(1)`), a single bad request
// (invalid input, duplicate email, a transient DB error, etc.) was crashing
// the ENTIRE server process - taking down every other request too - which is
// why Railway showed "Application failed to respond" after a failed signup.
import 'express-async-errors';

import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { errorHandler } from './middleware/error.js';
import { adminApiRoutes } from './routes/admin-api.routes.js';
import { authRoutes } from './routes/auth.routes.js';
import { kycRoutes } from './routes/kyc.routes.js';
import { transactionRoutes } from './routes/transaction.routes.js';
import { userRoutes } from './routes/user.routes.js';
import { vtuRoutes } from './routes/vtu.routes.js';
import { walletRoutes } from './routes/wallet.routes.js';
import { webhookRoutes } from './routes/webhook.routes.js';

const ADMIN_ROOT_PATH = '/admin';

export function createApp() {
  const app = express();

  app.get('/health', (_req, res) => {
    res.json({ status: true, service: 'imam-datasub-backend' });
  });

  app.use(helmet());
  app.use(cors());
  app.use(rateLimit({ windowMs: 60_000, limit: 120 }));

  // Mounted with a raw body parser, and BEFORE express.json() below, because Paystack's
  // signature is computed over the exact raw bytes of the request body.
  app.use('/api/webhooks', express.raw({ type: 'application/json' }), webhookRoutes);

  app.use(express.json({ limit: '1mb' }));

  app.use('/api/auth', authRoutes);
  app.use('/api/admin', adminApiRoutes);
  app.use('/api/user', userRoutes);
  app.use('/api/wallet', walletRoutes);
  app.use('/api/kyc', kycRoutes);
  app.use('/api', vtuRoutes);
  app.use('/api/transactions', transactionRoutes);

  let adminRouterPromise: Promise<express.Router> | null = null;
  app.use(ADMIN_ROOT_PATH, async (req, res, next) => {
    try {
      adminRouterPromise ??= import('./admin/setup.js').then(({ buildAdminRouter }) => {
        console.log('[admin] Building AdminJS router');
        return buildAdminRouter().router;
      });
      const adminRouter = await adminRouterPromise;
      return adminRouter(req, res, next);
    } catch (error) {
      console.error('[admin] Failed to build AdminJS router', error);
      adminRouterPromise = null;
      return next(error);
    }
  });

  app.use(errorHandler);
  return app;
}
