import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { buildAdminRouter, ADMIN_ROOT_PATH } from './admin/setup.js';
import { errorHandler } from './middleware/error.js';
import { adminApiRoutes } from './routes/admin-api.routes.js';
import { authRoutes } from './routes/auth.routes.js';
import { transactionRoutes } from './routes/transaction.routes.js';
import { userRoutes } from './routes/user.routes.js';
import { vtuRoutes } from './routes/vtu.routes.js';
import { walletRoutes } from './routes/wallet.routes.js';
import { webhookRoutes } from './routes/webhook.routes.js';

const EMAIL_CONFIRMED_HTML = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Email Confirmed - IMAM DATASUB</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 24px;
    }
    .card {
      background: #ffffff;
      border-radius: 16px;
      padding: 40px 32px;
      max-width: 400px;
      width: 100%;
      text-align: center;
      box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
    }
    .icon {
      width: 72px;
      height: 72px;
      background: #dcfce7;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 24px;
    }
    .icon svg {
      width: 36px;
      height: 36px;
    }
    h1 {
      font-size: 22px;
      color: #0f172a;
      margin-bottom: 12px;
    }
    p {
      font-size: 15px;
      color: #64748b;
      line-height: 1.5;
      margin-bottom: 24px;
    }
    .brand {
      font-size: 13px;
      color: #94a3b8;
      margin-top: 24px;
      letter-spacing: 0.5px;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">
      <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M20 6L9 17L4 12" stroke="#16a34a" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
      </svg>
    </div>
    <h1>Email Confirmed!</h1>
    <p>Your email address has been successfully verified. You can now return to the IMAM DATASUB app and log in.</p>
    <div class="brand">IMAM DATASUB</div>
  </div>
</body>
</html>`;

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

  // Simple static landing page Supabase redirects to after a user confirms
  // their email via the link sent to their inbox. No auth/session logic
  // happens here — Supabase already confirms the account server-side before
  // redirecting; this page is purely a friendly "you're done" message.
  app.get('/email-confirmed', (_req, res) => {
    res.set('Content-Type', 'text/html').send(EMAIL_CONFIRMED_HTML);
  });

  // Mounted with a raw body parser, and BEFORE express.json() below, because Paystack's
  // signature is computed over the exact raw bytes of the request body.
  app.use('/api/webhooks', express.raw({ type: 'application/json' }), webhookRoutes);

  app.use(express.json({ limit: '1mb' }));

  app.use('/api/auth', authRoutes);
  app.use('/api/admin', adminApiRoutes);
  app.use('/api/user', userRoutes);
  app.use('/api/wallet', walletRoutes);
  app.use('/api', vtuRoutes);
  app.use('/api/transactions', transactionRoutes);

  app.use(errorHandler);
  return app;
}
