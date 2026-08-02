import AdminJS from 'adminjs';
import AdminJSExpress from '@adminjs/express';
import session from 'express-session';
import connectPgSimple from 'connect-pg-simple';
import pg from 'pg';
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

// A separate, small pg Pool just for session storage - deliberately not routed
// through Prisma, since connect-pg-simple needs a raw pg client to manage its
// own `session` table (auto-created below via createTableIfMissing). This
// pool is cheap: session reads/writes are infrequent compared to API traffic.
//
// ssl.rejectUnauthorized is explicitly false here because node-postgres does
// full certificate-chain validation and rejects Supabase's pooler cert with
// "self-signed certificate in certificate chain" otherwise - this is a
// known node-postgres/Supabase interaction (see Supabase's own Node.js
// connection docs), distinct from Prisma's connection to this same
// DATABASE_URL, which uses its own TLS stack and isn't affected. The
// connection itself is still encrypted; this only skips validating the CA
// chain, which is the standard accepted workaround for this combination.
const sessionPool = new pg.Pool({
  connectionString: env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});
const PgSession = connectPgSimple(session);
const adminSessionStore = new PgSession({
  pool: sessionPool,
  tableName: 'admin_session',
  createTableIfMissing: true,
  // Prunes expired rows periodically instead of on every request.
  pruneSessionInterval: 60 * 15
});

export async function buildAdminRouter() {
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

  if (env.NODE_ENV !== 'production') {
    // Live-rebuilds the frontend bundle on file changes during local development.
    void admin.watch();
  } else {
    // AdminJSExpress.buildAuthenticatedRouter() below also calls admin.initialize()
    // internally, but WITHOUT awaiting it (fire-and-forget) - so the router it
    // returns can start serving requests before the bundle has finished writing
    // to disk. On a fresh deploy that raced against a stale/partial .adminjs/bundle.js
    // (or a corrupt in-progress write), which is what produced "Unexpected token"
    // in the browser: the first request(s) got served whatever was on disk at
    // that instant, not the freshly-built bundle. Awaiting it here ourselves,
    // before this function's promise resolves, guarantees a complete, valid
    // bundle exists before app.ts starts routing any request to this router.
    console.log('[admin] Building AdminJS frontend bundle...');
    await admin.initialize();
    console.log('[admin] AdminJS frontend bundle ready');
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
      secret: env.ADMIN_SESSION_SECRET,
      // Was express-session's default in-memory store, which loses every active
      // session on a restart/redeploy and can't be shared across more than one
      // instance — either of which reproduces exactly "login succeeds, next
      // request bounces back to /admin/login". Persisting sessions in the same
      // Postgres database Prisma already talks to fixes that: a redeploy (or a
      // second instance, if this ever scales beyond one) shares the same
      // session table instead of each holding its own private, empty one.
      store: adminSessionStore,
      cookie: {
        // Explicit rather than left to express-session's default, since without
        // `app.set('trust proxy', ...)` upstream (see app.ts), auto-detecting
        // "is this request secure" behind Railway's proxy is unreliable — this
        // makes the intent unambiguous instead of depending on that detection.
        secure: env.NODE_ENV === 'production',
        httpOnly: true,
        maxAge: 8 * 60 * 60 * 1000 // 8 hours
      }
    }
  );

  return { admin, router };
}
