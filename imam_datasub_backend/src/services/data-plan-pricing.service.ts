import { env } from '../config/env.js';
import { koboToNaira, nairaToKobo } from '../lib/money.js';
import { prisma } from '../lib/prisma.js';
import type { DataPlan } from './data-plans.data.js';

export type PricedDataPlan = DataPlan & {
  providerAmount: number;
  sellingAmount: number;
  profit: number;
  isActive: boolean;
  pricingId?: string;
  planType?: string;
};

function planTypeFrom(name: string) {
  const [type] = name.split(' - ');
  return type && type !== name ? type.trim().toUpperCase() : undefined;
}

function defaultSellingPrice(providerCost: number) {
  return Math.ceil(
    providerCost +
      (providerCost * env.DATA_PLAN_MARKUP_PERCENT) / 100 +
      env.DATA_PLAN_MARKUP_NAIRA
  );
}

export class DataPlanPricingService {
  async applyPricing(plans: DataPlan[], network: string) {
    // NOTE: This runs sequentially on purpose. The Supabase/Railway connection
    // pool is capped (connection_limit=1 in DATABASE_URL) to avoid PgBouncer
    // "prepared statement does not exist" errors under transaction pooling.
    // Firing all upserts concurrently (Promise.all + map) exhausts that single
    // connection slot and every other upsert times out waiting for it.
    const priced: PricedDataPlan[] = [];

    for (const plan of plans) {
      const providerCostKobo = nairaToKobo(plan.amount);
      const pricing = await prisma.dataPlanPricing.upsert({
        where: {
          provider_providerPlanId: {
            provider: 'alrahuz',
            providerPlanId: plan.id
          }
        },
        update: {
          network,
          networkId: plan.networkId,
          planType: planTypeFrom(plan.name),
          name: plan.name,
          validity: plan.validity,
          providerCostKobo,
          lastSeenAt: new Date()
        },
        create: {
          provider: 'alrahuz',
          providerPlanId: plan.id,
          network,
          networkId: plan.networkId,
          planType: planTypeFrom(plan.name),
          name: plan.name,
          validity: plan.validity,
          providerCostKobo
        }
      });

      const providerAmount = koboToNaira(pricing.providerCostKobo);
      const sellingAmount = pricing.sellingPriceKobo
        ? koboToNaira(pricing.sellingPriceKobo)
        : defaultSellingPrice(providerAmount);

      priced.push({
        ...plan,
        amount: sellingAmount,
        providerAmount,
        sellingAmount,
        profit: sellingAmount - providerAmount,
        isActive: pricing.isActive,
        pricingId: pricing.id,
        planType: pricing.planType ?? planTypeFrom(plan.name)
      } satisfies PricedDataPlan);
    }

    return priced.filter((plan) => plan.isActive);
  }

  async getPricingRows(network?: string) {
    const rows = await prisma.dataPlanPricing.findMany({
      where: network ? { network: network.toUpperCase() } : undefined,
      orderBy: [{ networkId: 'asc' }, { planType: 'asc' }, { providerCostKobo: 'asc' }]
    });

    return rows.map((row) => {
      const providerCost = koboToNaira(row.providerCostKobo);
      const sellingPrice = row.sellingPriceKobo
        ? koboToNaira(row.sellingPriceKobo)
        : defaultSellingPrice(providerCost);
      return {
        id: row.id,
        provider_plan_id: row.providerPlanId,
        network: row.network,
        network_id: row.networkId,
        plan_type: row.planType,
        name: row.name,
        validity: row.validity,
        provider_cost: providerCost,
        selling_price: sellingPrice,
        profit: sellingPrice - providerCost,
        is_active: row.isActive,
        last_seen_at: row.lastSeenAt.toISOString(),
        updated_at: row.updatedAt.toISOString()
      };
    });
  }

  async updatePricing(
    id: string,
    params: { sellingPrice?: number | null; isActive?: boolean }
  ) {
    const row = await prisma.dataPlanPricing.update({
      where: { id },
      data: {
        ...(params.sellingPrice === null
          ? { sellingPriceKobo: null }
          : params.sellingPrice !== undefined
            ? { sellingPriceKobo: nairaToKobo(params.sellingPrice) }
            : {}),
        ...(params.isActive !== undefined ? { isActive: params.isActive } : {})
      }
    });

    const providerCost = koboToNaira(row.providerCostKobo);
    const sellingPrice = row.sellingPriceKobo
      ? koboToNaira(row.sellingPriceKobo)
      : defaultSellingPrice(providerCost);

    return {
      id: row.id,
      provider_plan_id: row.providerPlanId,
      network: row.network,
      name: row.name,
      provider_cost: providerCost,
      selling_price: sellingPrice,
      profit: sellingPrice - providerCost,
      is_active: row.isActive
    };
  }

  async applyMarkup(params: { network?: string; markupNaira: number; markupPercent: number }) {
    const rows = await prisma.dataPlanPricing.findMany({
      where: params.network ? { network: params.network.toUpperCase() } : undefined
    });

    // Sequential for the same reason as applyPricing() above: connection_limit=1
    // in DATABASE_URL means concurrent updates exhaust the pool and time out.
    for (const row of rows) {
      const providerCost = koboToNaira(row.providerCostKobo);
      const sellingPrice = Math.ceil(
        providerCost + (providerCost * params.markupPercent) / 100 + params.markupNaira
      );
      await prisma.dataPlanPricing.update({
        where: { id: row.id },
        data: { sellingPriceKobo: nairaToKobo(sellingPrice) }
      });
    }

    return { updated: rows.length };
  }
}

export const dataPlanPricingService = new DataPlanPricingService();
