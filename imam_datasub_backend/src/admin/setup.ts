import AdminJS from 'adminjs';
import AdminJSExpress from '@adminjs/express';
import { Database, Resource } from '@adminjs/prisma';
import { env } from '../config/env.js';
import { authenticateAdmin } from './auth.js';
import { componentLoader } from './component-loader.js';
import { userResource } from './resources/user.resource.js';
import { transactionResource } from './resources/transaction.resource.js';
import { adminUserResource } from './resources/admin-user.resource.js';
import { adminAuditLogResource } from './resources/audit-log.resource.js';
import { dataPlanPricingResource } from './resources/data-plan-pricing.resource.js';
import { couponResource } from './resources/coupon.resource.js';
import { providerBalanceResource } from './resources/provider-balance.resource.js';
import { notificationBroadcastResource } from './resources/notification-broadcast.resource.js';

AdminJS.registerAdapter({ Database, Resource });

export const ADMIN_ROOT_PATH = '/admin';

export function buildAdminRouter() {
  const admin = new AdminJS({
    rootPath: ADMIN_ROOT_PATH,
    componentLoader,
    branding: {
      companyName: 'Imam Datasub Admin',
      withMadeWithLove: false
    },
    resources: [
      userResource,
      transactionResource,
      dataPlanPricingResource,
      couponResource,
      providerBalanceResource,
      notificationBroadcastResource,
      adminUserResource,
      adminAuditLogResource
    ]
  });

  // Live-rebuilds the frontend bundle on file changes during local development.
  // In production the bundle should be built ahead of time (see README notes).
  if (env.NODE_ENV !== 'production') {
    void admin.watch();
  }

  const router = AdminJSExpress.buildAuthenticatedRouter(
    admin,
    {
      authenticate: async (email: string, password: string) => authenticateAdmin(email, password),
      cookiePassword: env.ADMIN_SESSION_SECRET,
      cookieName: 'imam_admin_sid'
    },
    null,
    {
      resave: false,
      saveUninitialized: false,
      secret: env.ADMIN_SESSION_SECRET
      // NOTE: this uses express-session's default in-memory store, which is fine for
      // a single dev/staging process only — it leaks memory and won't work across
      // multiple server instances or survive a restart. Before running more than one
      // backend instance in production, swap this for a persistent store such as
      // connect-pg-simple pointed at the same Postgres database.
    }
  );

  return { admin, router };
}
