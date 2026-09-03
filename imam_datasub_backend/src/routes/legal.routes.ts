import { Router } from 'express';
import { renderLegalPage } from '../lib/render-legal-page.js';
import { renderDeleteAccountPage } from '../lib/render-delete-account-page.js';
import { EFFECTIVE_DATE, PRIVACY_SECTIONS, TERMS_SECTIONS } from '../lib/legal-content.js';

export const legalRoutes = Router();

// Matches imam_datasub/lib/core/config/app_config.dart's supportEmailDisplay/supportWhatsApp.
// If you change contact details there, update these two constants too.
const SUPPORT_EMAIL = 'abdulmhassan02@gmail.com / imam.datasub21@gmail.com';
const SUPPORT_WHATSAPP = '+2348035679448';

legalRoutes.get('/privacy-policy', (_req, res) => {
  res.type('html').send(
    renderLegalPage({
      title: 'Privacy Policy',
      effectiveDate: EFFECTIVE_DATE,
      sections: PRIVACY_SECTIONS,
      supportEmail: SUPPORT_EMAIL,
      supportWhatsApp: SUPPORT_WHATSAPP
    })
  );
});

legalRoutes.get('/terms', (_req, res) => {
  res.type('html').send(
    renderLegalPage({
      title: 'Terms & Conditions',
      effectiveDate: EFFECTIVE_DATE,
      sections: TERMS_SECTIONS,
      supportEmail: SUPPORT_EMAIL,
      supportWhatsApp: SUPPORT_WHATSAPP
    })
  );
});

// Public "Delete account URL" required by Google Play's Data safety form.
// Must be reachable with no login and no app install. See
// render-delete-account-page.ts for the actual content/steps.
legalRoutes.get('/delete-account', (_req, res) => {
  res.type('html').send(
    renderDeleteAccountPage({
      supportEmail: SUPPORT_EMAIL,
      supportWhatsApp: SUPPORT_WHATSAPP
    })
  );
});


