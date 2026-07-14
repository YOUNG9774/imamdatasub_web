import { Router } from 'express';
import { nanoid } from 'nanoid';
import { z } from 'zod';
import { prisma } from '../lib/prisma.js';
import { koboToNaira } from '../lib/money.js';
import { requireAuth } from '../middleware/auth.js';
import { paystackService } from '../services/paystack.service.js';
import { createPendingFunding, creditWalletByReference, verifyPin } from '../services/wallet.service.js';

export const walletRoutes = Router();

walletRoutes.use(requireAuth);

walletRoutes.get('/balance', async (req, res) => {
  const user = await prisma.user.findUniqueOrThrow({ where: { id: req.user!.id } });
  res.json({
    balance: koboToNaira(user.walletBalanceKobo),
    currency: 'NGN',
    virtual_account_number: user.virtualAccountNumber,
    virtual_account_bank: user.virtualAccountBank
  });
});

walletRoutes.get('/virtual-account', async (req, res) => {
  const user = await prisma.user.findUniqueOrThrow({ where: { id: req.user!.id } });
  res.json({
    balance: koboToNaira(user.walletBalanceKobo),
    currency: 'NGN',
    virtual_account_number: user.virtualAccountNumber,
    virtual_account_bank: user.virtualAccountBank
  });
});

walletRoutes.post('/fund', async (req, res) => {
  const body = z.object({
    amount: z.number().positive(),
    payment_method: z.string().optional()
  }).parse(req.body);

  const user = await prisma.user.findUniqueOrThrow({ where: { id: req.user!.id } });
  const reference = `IDS-FUND-${Date.now()}-${nanoid(8).toUpperCase()}`;

  // Record the attempt as PENDING first — the wallet balance only changes once
  // Paystack confirms payment via webhook (or the /fund/verify fallback below).
  await createPendingFunding({
    userId: user.id,
    amount: body.amount,
    reference,
    metadata: { payment_method: body.payment_method ?? 'card' }
  });

  const paystack = await paystackService.initializeTransaction({
    email: user.email,
    amountKobo: BigInt(Math.round(body.amount * 100)),
    reference
  });

  res.json({
    status: true,
    message: 'Payment initialized',
    data: {
      amount: body.amount,
      reference,
      authorization_url: paystack.authorization_url
    }
  });
});

/**
 * Fallback for the rare case a Paystack webhook doesn't arrive (network blip, server
 * restart mid-delivery). The Flutter app should call this after the payment webview
 * redirects back, so the wallet is credited even if the webhook is delayed or lost.
 * Safe to call repeatedly — creditWalletByReference is idempotent.
 */
walletRoutes.post('/fund/verify', async (req, res) => {
  const body = z.object({ reference: z.string() }).parse(req.body);

  const transaction = await prisma.transaction.findFirst({
    where: { reference: body.reference, userId: req.user!.id }
  });
  if (!transaction) {
    return res.status(404).json({ status: false, message: 'Transaction not found' });
  }

  const verified = await paystackService.verifyTransaction(body.reference);
  if (verified.status === 'success') {
    const updated = await creditWalletByReference(body.reference);
    return res.json({
      status: true,
      message: 'Wallet funded',
      data: { balance: koboToNaira(updated.balanceAfterKobo) }
    });
  }

  res.json({ status: false, message: `Payment ${verified.status}` });
});

walletRoutes.post('/transfer', async (req, res) => {
  const body = z.object({
    recipient: z.string(),
    amount: z.number().positive(),
    pin: z.string()
  }).parse(req.body);

  await verifyPin(req.user!.id, body.pin);
  res.json({ status: true, message: 'Transfer route scaffolded', data: { recipient: body.recipient } });
});
