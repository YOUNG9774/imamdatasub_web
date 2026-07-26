import { KycStatus } from '@prisma/client';
import { ApiError } from '../middleware/error.js';
import { prisma } from '../lib/prisma.js';
import { paystackService } from './paystack.service.js';

/** Splits "Sunusi Usama" -> { firstName: "Sunusi", lastName: "Usama" }. Paystack requires both separately. */
function splitFullName(fullName: string) {
  const parts = fullName.trim().split(/\s+/);
  const firstName = parts[0] ?? fullName;
  const lastName = parts.slice(1).join(' ') || firstName;
  return { firstName, lastName };
}

/**
 * The full BVN verification flow:
 *   1. Resolve the BVN on its own (identity sanity-check).
 *   2. Create (or reuse) a Paystack customer for this user.
 *   3. Validate that customer with BVN + bank account (required by Paystack for
 *      Financial Services / Betting / General Services categories before a DVA
 *      can be issued).
 *   4. Create the Dedicated Virtual Account and persist it on the user.
 *
 * We deliberately do NOT store the raw BVN anywhere - only the last 4 digits
 * (for support/reference purposes) once the flow succeeds.
 */
export async function verifyBvnAndActivateWallet(params: {
  userId: string;
  bvn: string;
  bankCode: string;
  accountNumber: string;
}) {
  const { userId, bvn, bankCode, accountNumber } = params;

  if (!/^\d{11}$/.test(bvn)) {
    throw new ApiError(422, 'BVN must be exactly 11 digits', 'INVALID_BVN');
  }
  if (!/^\d{10}$/.test(accountNumber)) {
    throw new ApiError(422, 'Account number must be exactly 10 digits', 'INVALID_ACCOUNT_NUMBER');
  }

  const user = await prisma.user.findUniqueOrThrow({ where: { id: userId } });

  if (user.kycStatus === KycStatus.VERIFIED && user.virtualAccountNumber) {
    // Already done - return the existing account rather than re-running (and re-billing) verification.
    return {
      kycStatus: user.kycStatus,
      virtualAccountNumber: user.virtualAccountNumber,
      virtualAccountBank: user.virtualAccountBank
    };
  }

  await prisma.user.update({ where: { id: userId }, data: { kycStatus: KycStatus.PENDING } });

  const { firstName, lastName } = splitFullName(user.fullName);

  try {
    // Step 1: confirm the BVN itself resolves to a real identity. Non-fatal on its
    // own beyond this check - we don't block on a name-mismatch here since legal
    // name formatting (middle names, maiden names, etc.) varies too much to hard-fail on.
    await paystackService.resolveBvn(bvn);

    // Step 2: reuse an existing Paystack customer_code if we already made one for
    // this user (e.g. a retry after a failed validation), otherwise create one.
    let customerCode = user.paystackCustomerCode;
    if (!customerCode) {
      const customer = await paystackService.createCustomer({
        email: user.email,
        firstName,
        lastName,
        phone: user.phone
      });
      customerCode = customer.customer_code;
      await prisma.user.update({ where: { id: userId }, data: { paystackCustomerCode: customerCode } });
    }

    // Step 3: validate identity - this is the step that actually requires BVN + bank account.
    await paystackService.validateCustomer(customerCode, {
      firstName,
      lastName,
      bvn,
      bankCode,
      accountNumber
    });

    // Step 4: issue the actual Dedicated Virtual Account.
    const dva = await paystackService.createDedicatedVirtualAccount({ customerCode });

    const bvnLast4 = bvn.slice(-4);

    await prisma.user.update({
      where: { id: userId },
      data: {
        kycStatus: KycStatus.VERIFIED,
        virtualAccountNumber: dva.account_number,
        virtualAccountBank: dva.bank.name,
        bvnLast4,
        bvnVerifiedAt: new Date(),
        kycFailureReason: null
      }
    });

    return {
      kycStatus: KycStatus.VERIFIED,
      virtualAccountNumber: dva.account_number,
      virtualAccountBank: dva.bank.name
    };
  } catch (error) {
    const message = error instanceof ApiError ? error.message : 'Verification failed unexpectedly';
    await prisma.user.update({
      where: { id: userId },
      data: { kycStatus: KycStatus.REJECTED, kycFailureReason: message }
    });
    throw error;
  }
}

export async function getKycStatus(userId: string) {
  const user = await prisma.user.findUniqueOrThrow({ where: { id: userId } });
  return {
    kycStatus: user.kycStatus,
    kycFailureReason: user.kycFailureReason,
    bvnLast4: user.bvnLast4,
    bvnVerifiedAt: user.bvnVerifiedAt,
    virtualAccountNumber: user.virtualAccountNumber,
    virtualAccountBank: user.virtualAccountBank
  };
}

export async function listSupportedBanks() {
  return paystackService.listBanks();
}
