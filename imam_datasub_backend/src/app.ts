import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { buildAdminRouter, ADMIN_ROOT_PATH } from './admin/setup.js';
import { errorHandler } from './middleware/error.js';
import { authRoutes } from './routes/auth.routes.js';
import { transactionRoutes } from './routes/transaction.routes.js';
import { userRoutes } from './routes/user.routes.js';
import { vtuRoutes } from './routes/vtu.routes.js';
import { walletRoutes } from './routes/wallet.routes.js';
import { webhookRoutes } from './routes/webhook.routes.js';

export function createApp() {
  const app = express();

  // Mounted BEFORE helmet(), because helmet's default Content-Security-Policy blocks
  // the inline scripts/styles AdminJS's own bundle relies on. The rest of the API
  // (mounted below) keeps the full helmet + CORS + rate-limit stack.
  const { router: adminRouter } = buildAdminRouter();
  app.use(ADMIN_ROOT_PATH, adminRouter);

  app.use(helmet());
  app.use(cors());
  app.use(rateLimit({ windowMs: 60_000, limit: 120 }));

  app.get('/health', (_req, res) => {
    res.json({ status: true, service: 'imam-datasub-backend' });
  });

  // Mounted with a raw body parser, and BEFORE express.json() below, because Paystack's
  // signature is computed over the exact raw bytes of the request body.
  app.use('/api/webhooks', express.raw({ type: 'application/json' }), webhookRoutes);

  app.use(express.json({ limit: '1mb' }));

  app.use('/api', authRoutes);
  app.use('/api/user', userRoutes);
  app.use('/api/wallet', walletRoutes);
  app.use('/api', vtuRoutes);
  app.use('/api/transactions', transactionRoutes);

  app.use(errorHandler);
  return app;
}
