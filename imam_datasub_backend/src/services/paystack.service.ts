import { env } from '../config/env.js';
import { ApiError } from '../middleware/error.js';

const PAYSTACK_BASE_URL = 'https://api.paystack.co';

function headers() {
  if (!env.PAYSTACK_SECRET_KEY) {
    throw new ApiError(500, 'Paystack is not configured on this server', 'PAYSTACK_NOT_CONFIGURED');
  }
  return {
    Authorization: `Bearer ${env.PAYSTACK_SECRET_KEY}`,
    'Content-Type': 'application/json'
  };
}

type PaystackInitializeResponse = {
  status: boolean;
  message: string;
  data: { authorization_url: string; access_code: string; reference: string };
};

type PaystackVerifyResponse = {
  status: boolean;
  message: string;
  data: { status: string; amount: number; currency: string; reference: string };
};

export const paystackService = {
  /**
   * Starts a payment. `amountKobo` is the amount in kobo — Paystack's NGN base unit
   * matches our wallet storage unit exactly, so no conversion is needed here.
   */
  async initializeTransaction(params: { email: string; amountKobo: bigint; reference: string }) {
    const response = await fetch(`${PAYSTACK_BASE_URL}/transaction/initialize`, {
      method: 'POST',
      headers: headers(),
      body: JSON.stringify({
        email: params.email,
        amount: params.amountKobo.toString(),
        reference: params.reference,
        callback_url: env.PAYSTACK_CALLBACK_URL
      })
    });

    const data = (await response.json()) as PaystackInitializeResponse;
    if (!response.ok || !data.status) {
      throw new ApiError(502, data.message ?? 'Failed to initialize payment', 'PAYSTACK_INIT_FAILED');
    }
    return data.data;
  },

  /**
   * Server-to-server verification. Never trust a webhook payload's amount/status alone —
   * always re-check directly with Paystack before crediting a wallet.
   */
  async verifyTransaction(reference: string) {
    const response = await fetch(`${PAYSTACK_BASE_URL}/transaction/verify/${encodeURIComponent(reference)}`, {
      headers: headers()
    });

    const data = (await response.json()) as PaystackVerifyResponse;
    if (!response.ok || !data.status) {
      throw new ApiError(502, data.message ?? 'Failed to verify payment', 'PAYSTACK_VERIFY_FAILED');
    }
    return data.data;
  }
};
