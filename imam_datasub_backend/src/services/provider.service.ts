import { env } from '../config/env.js';
import { ApiError } from '../middleware/error.js';
import { DATA_PLANS } from './data-plans.data.js';

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

/** Confirmed from your Alrahuz dashboard's Network List. */
export const NETWORK_IDS: Record<string, number> = {
  MTN: 1,
  GLO: 2,
  '9MOBILE': 3,
  AIRTEL: 4,
  SMILE: 5
};

export class ProviderService {
  async getDataPlans(network: string) {
    if (env.MOCK_PROVIDER) {
      return [
        { id: `${network}-1gb`, name: '1GB - 30 Days', amount: 500, validity: '30 days' },
        { id: `${network}-2gb`, name: '2GB - 30 Days', amount: 900, validity: '30 days' },
        { id: `${network}-5gb`, name: '5GB - 30 Days', amount: 2000, validity: '30 days' }
      ];
    }

    const networkId = NETWORK_IDS[network.toUpperCase()];
    return DATA_PLANS.filter((plan) => plan.networkId === networkId);
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
        network: Number(input.network),
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
        network: Number(input.network),
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
}

export const providerService = new ProviderService();
