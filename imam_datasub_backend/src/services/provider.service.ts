import { env } from '../config/env.js';
import { ApiError } from '../middleware/error.js';
import { dataPlanPricingService } from './data-plan-pricing.service.js';
import { DATA_PLANS, type DataPlan } from './data-plans.data.js';

export type ProviderPurchaseInput = {
  network: string; // Alrahuz network ID, e.g. "1" for MTN — see NETWORK_IDS below
  phone: string;
  amount: number;
  planId?: string; // Alrahuz plan ID, required for data purchases
  reference: string;
};

/**
 * Confirmed from a real successful /api/data/ response on 2026-07-14 (HTTP 201):
 * {
 *   "id": 308232124,
 *   "ident": "Data19309363031182999583",
 *   "api_response": "Congrats! You have successfully gifted ...",
 *   "customer_ref": "",
 *   "network": 3,
 *   "balance_before": "65.0",
 *   "balance_after": "40.0",
 *   "mobile_number": "08012345678",
 *   "plan": 305,
 *   "Status": "successful",
 *   "plan_network": "9MOBILE",
 *   "plan_type": "CORPORATE GIFTING",
 *   "plan_name": "25.0MB",
 *   "plan_amount": "25.0",
 *   "create_date": "2026-07-14T11:15:48.723270",
 *   "Ported_number": true
 * }
 * The failure shape hasn't been observed yet (e.g. insufficient Alrahuz balance,
 * invalid plan/network combo, invalid phone) — if `Status` ever comes back as
 * something other than "successful", or the request fails outright, treat it as a
 * failure. Tighten this further once a real failure response is seen.
 */
type AlrahuzResponse = {
  id?: number;
  ident?: string;
  api_response?: string;
  Status?: string;
  detail?: string; // present on auth errors, e.g. "Authentication credentials were not provided."
  [key: string]: unknown;
};

type PlanCacheEntry = {
  expiresAt: number;
  plans: Awaited<ReturnType<typeof dataPlanPricingService.applyPricing>>;
};

const planCache = new Map<string, PlanCacheEntry>();

/** Confirmed from your Alrahuz dashboard's Network List. */
export const NETWORK_IDS: Record<string, number> = {
  MTN: 1,
  GLO: 2,
  '9MOBILE': 3,
  AIRTEL: 4,
  SMILE: 5
};

export class ProviderService {
  clearDataPlanCache(network?: string) {
    if (!network) {
      planCache.clear();
      return;
    }

    const networkId = NETWORK_IDS[network.toUpperCase()];
    if (networkId) planCache.delete(String(networkId));
  }

  async refreshDataPlans(network: string) {
    this.clearDataPlanCache(network);
    return this.getDataPlans(network);
  }

  async getDataPlans(network: string, category?: string) {
    const plans = await this.getAllDataPlans(network);
    if (!category) return plans;

    const normalized = category.trim().toUpperCase();
    return plans.filter((plan) => (plan.planType ?? '').toUpperCase() === normalized);
  }

  /** Distinct Data Types (SME, SME2, GIFTING, etc.) that currently have at least
   *  one plan for this network - drives the "Select Data Type" step, matching
   *  Alrahuz's own app UX. Computed from data, not hardcoded, so it stays
   *  correct even if a network temporarily has fewer/more categories. */
  async getDataPlanCategories(network: string) {
    const plans = await this.getAllDataPlans(network);
    const counts = new Map<string, number>();

    for (const plan of plans) {
      const type = plan.planType?.trim();
      if (!type) continue;
      counts.set(type, (counts.get(type) ?? 0) + 1);
    }

    return Array.from(counts.entries())
      .map(([category, planCount]) => ({ category, planCount }))
      .sort((a, b) => a.category.localeCompare(b.category));
  }

  private async getAllDataPlans(network: string) {
    if (env.MOCK_PROVIDER) {
      return dataPlanPricingService.applyPricing([
        { id: `${network}-1gb`, name: '1GB - 30 Days', amount: 500, validity: '30 days' },
        { id: `${network}-2gb`, name: '2GB - 30 Days', amount: 900, validity: '30 days' },
        { id: `${network}-5gb`, name: '5GB - 30 Days', amount: 2000, validity: '30 days' }
      ].map((plan) => ({ ...plan, networkId: NETWORK_IDS[network.toUpperCase()] ?? 1 })), network.toUpperCase());
    }

    const networkId = NETWORK_IDS[network.toUpperCase()];
    if (!networkId) {
      throw new ApiError(422, `Unsupported network: ${network}`, 'UNSUPPORTED_NETWORK');
    }

    const cached = planCache.get(String(networkId));
    if (cached && cached.expiresAt > Date.now()) {
      return cached.plans;
    }

    const livePlans = await this.fetchLiveDataPlans(network, networkId).catch((err) => {
      console.error(`[provider] live data plan fetch failed for ${network} (networkId=${networkId}):`, err);
      return [];
    });
    console.log(`[provider] ${network} (networkId=${networkId}): live=${livePlans.length} plans`);
    const rawPlans = livePlans.length > 0
      ? livePlans
      : DATA_PLANS.filter((plan) => plan.networkId === networkId);
    if (livePlans.length === 0) {
      console.warn(`[provider] ${network} (networkId=${networkId}): falling back to static snapshot, ${rawPlans.length} plans`);
    }
    const plans = await dataPlanPricingService.applyPricing(rawPlans, network.toUpperCase());
    console.log(`[provider] ${network} (networkId=${networkId}): ${plans.length} plans after pricing/isActive filter (out of ${rawPlans.length} raw)`);

    planCache.set(String(networkId), {
      expiresAt: Date.now() + env.ALRAHUZ_DATA_PLANS_CACHE_SECONDS * 1000,
      plans
    });

    return plans;
  }

  async getDataPlan(network: string, planId: string) {
    const plans = await this.getDataPlans(network);
    const plan = plans.find((item) => item.id === planId);
    if (!plan) {
      throw new ApiError(422, 'Selected data plan is no longer available', 'DATA_PLAN_UNAVAILABLE');
    }
    return plan;
  }

  async buyData(input: ProviderPurchaseInput) {
    if (env.MOCK_PROVIDER) {
      return { status: true, providerRef: `MOCK-${input.reference}`, message: 'Data purchase queued' };
    }
    if (!input.planId) {
      throw new ApiError(422, 'planId is required for data purchases', 'MISSING_PLAN_ID');
    }

    const response = await fetch(`${env.ALRAHUZ_BASE_URL}/data/`, {
      method: 'POST',
      headers: this.headers(),
      body: JSON.stringify({
        network: this.networkId(input.network),
        mobile_number: input.phone,
        plan: Number(input.planId),
        Ported_number: true
      })
    });

    return this.normalize(response, input.reference);
  }

  async buyAirtime(input: ProviderPurchaseInput) {
    if (env.MOCK_PROVIDER) {
      return { status: true, providerRef: `MOCK-${input.reference}`, message: 'Airtime purchase queued' };
    }

    const response = await fetch(`${env.ALRAHUZ_BASE_URL}/topup/`, {
      method: 'POST',
      headers: this.headers(),
      body: JSON.stringify({
        network: this.networkId(input.network),
        amount: input.amount,
        mobile_number: input.phone,
        Ported_number: true,
        airtime_type: 'VTU'
      })
    });

    return this.normalize(response, input.reference);
  }

  /**
   * Alrahuz returns HTTP 200/201 with a body `Status` field ("successful" on success),
   * separate from HTTP status. A non-2xx HTTP response (e.g. 401 with a `detail` field)
   * is also treated as a failure. `ident` (Alrahuz's own transaction ID) is preferred as
   * providerRef when present, since it's what you'd use to query the transaction status
   * back from Alrahuz later — falls back to our own reference if it's missing.
   */
  private async normalize(response: Response, reference: string) {
    const body = (await response.json().catch(() => ({}))) as AlrahuzResponse;

    if (!response.ok) {
      return {
        status: false,
        providerRef: reference,
        message: body.detail ?? body.api_response ?? `Provider returned HTTP ${response.status}`
      };
    }

    const succeeded = body.Status?.toLowerCase() === 'successful';

    return {
      status: succeeded,
      providerRef: body.ident ?? reference,
      message: body.api_response ?? (succeeded ? 'Transaction successful' : `Provider status: ${body.Status ?? 'unknown'}`),
      raw: body
    };
  }

  private headers() {
    return {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      Authorization: `Token ${env.ALRAHUZ_API_TOKEN ?? ''}`
    };
  }

  private async fetchLiveDataPlans(network: string, networkId: number) {
    const path = env.ALRAHUZ_DATA_PLANS_PATH.replace('{network}', encodeURIComponent(String(networkId)))
      .replace('{networkName}', encodeURIComponent(network.toUpperCase()));
    const baseUrl = env.ALRAHUZ_BASE_URL.replace(/\/$/, '');
    const cleanPath = path.startsWith('/') ? path : `/${path}`;
    const url = new URL(`${baseUrl}${cleanPath}`);
    if (!env.ALRAHUZ_DATA_PLANS_PATH.includes('{network}')) {
      url.searchParams.set('network', String(networkId));
    }

    const response = await fetch(url, { headers: this.headers() });
    if (!response.ok) return [];

    const body = (await response.json().catch(() => null)) as unknown;
    return this.extractPlans(body, networkId);
  }

  private extractPlans(body: unknown, networkId: number): DataPlan[] {
    const list = this.findPlanArray(body);
    if (!list) return [];

    return list
      .map((item) => this.normalizePlan(item, networkId))
      .filter((plan): plan is DataPlan => Boolean(plan));
  }

  private findPlanArray(body: unknown): unknown[] | undefined {
    if (Array.isArray(body)) return body;
    if (!body || typeof body !== 'object') return undefined;

    const record = body as Record<string, unknown>;
    for (const key of ['data', 'plans', 'results', 'plan', 'DataPlan']) {
      const value = record[key];
      if (Array.isArray(value)) return value;
    }

    return undefined;
  }

  private normalizePlan(item: unknown, fallbackNetworkId: number): DataPlan | undefined {
    if (!item || typeof item !== 'object') return undefined;
    const record = item as Record<string, unknown>;

    const id = this.stringValue(record.id ?? record.plan_id ?? record.plan);
    const amount = this.numberValue(record.amount ?? record.price ?? record.plan_amount);
    if (!id || !amount) return undefined;

    const networkId = this.numberValue(record.network ?? record.network_id ?? record.networkId) ?? fallbackNetworkId;
    if (networkId !== fallbackNetworkId) return undefined;

    const planType = this.stringValue(record.plan_type ?? record.type ?? record.category);
    const planName = this.stringValue(record.plan_name ?? record.name ?? record.data_size ?? record.size) || `Plan ${id}`;
    const validity = this.stringValue(record.validity ?? record.duration ?? record.validity_period) || 'Validity varies';
    const name = planType && !planName.toUpperCase().includes(planType.toUpperCase())
      ? `${planType} - ${planName}`
      : planName;

    return { networkId, id, name, amount, validity };
  }

  private stringValue(value: unknown) {
    return typeof value === 'string' || typeof value === 'number' ? String(value).trim() : '';
  }

  private numberValue(value: unknown) {
    if (typeof value === 'number' && Number.isFinite(value)) return value;
    if (typeof value === 'string') {
      const parsed = Number(value.replace(/[^\d.]/g, ''));
      return Number.isFinite(parsed) ? parsed : undefined;
    }
    return undefined;
  }

  private networkId(network: string) {
    const mapped = NETWORK_IDS[network.toUpperCase()];
    if (mapped) return mapped;

    const numeric = Number(network);
    if (Number.isFinite(numeric) && numeric > 0) return numeric;

    throw new ApiError(422, `Unsupported network: ${network}`, 'UNSUPPORTED_NETWORK');
  }
}

export const providerService = new ProviderService();
