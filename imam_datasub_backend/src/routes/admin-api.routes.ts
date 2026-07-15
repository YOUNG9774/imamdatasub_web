import { Router } from 'express';
import { z } from 'zod';
import { dataPlanPricingService } from '../services/data-plan-pricing.service.js';
import { providerService } from '../services/provider.service.js';
import { requireAppAdmin, requireFinanceAdmin } from '../middleware/admin-auth.js';

export const adminApiRoutes = Router();

adminApiRoutes.use(requireAppAdmin);

function routeParam(value: string | string[] | undefined) {
  return Array.isArray(value) ? value[0] : value ?? '';
}

adminApiRoutes.get('/me', (req, res) => {
  res.json({ status: true, data: { admin: req.admin } });
});

adminApiRoutes.get('/data-prices', requireFinanceAdmin, async (req, res) => {
  const network = typeof req.query.network === 'string' ? req.query.network : undefined;
  const rows = await dataPlanPricingService.getPricingRows(network);
  res.json({ status: true, data: rows });
});

adminApiRoutes.post('/data-prices/sync/:network', requireFinanceAdmin, async (req, res) => {
  const network = routeParam(req.params.network);
  await providerService.refreshDataPlans(network);
  const rows = await dataPlanPricingService.getPricingRows(network);
  res.json({ status: true, data: rows });
});

adminApiRoutes.patch('/data-prices/:id', requireFinanceAdmin, async (req, res) => {
  const body = z.object({
    selling_price: z.number().positive().nullable().optional(),
    is_active: z.boolean().optional()
  }).parse(req.body);

  const row = await dataPlanPricingService.updatePricing(routeParam(req.params.id), {
    sellingPrice: body.selling_price,
    isActive: body.is_active
  });
  providerService.clearDataPlanCache(row.network);

  res.json({ status: true, data: row });
});

adminApiRoutes.post('/data-prices/apply-markup', requireFinanceAdmin, async (req, res) => {
  const body = z.object({
    network: z.string().optional(),
    markup_naira: z.number().min(0).default(0),
    markup_percent: z.number().min(0).default(0)
  }).parse(req.body);

  const result = await dataPlanPricingService.applyMarkup({
    network: body.network,
    markupNaira: body.markup_naira,
    markupPercent: body.markup_percent
  });
  providerService.clearDataPlanCache(body.network);

  res.json({ status: true, data: result });
});
