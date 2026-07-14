import { getModelByName } from '@adminjs/prisma';
import type { ResourceWithOptions } from 'adminjs';
import { prisma } from '../../lib/prisma.js';
import { manualWalletAdjustment } from '../../services/wallet.service.js';
import { logAdminAction } from '../audit.js';
import { Components } from '../component-loader.js';
import type { AdminSessionUser } from '../auth.js';

export const userResource: ResourceWithOptions = {
  resource: { model: getModelByName('User'), client: prisma },
  options: {
    id: 'User',
    navigation: { name: 'Customers', icon: 'Users' },
    listProperties: ['fullName', 'email', 'phone', 'walletBalanceKobo', 'kycStatus', 'createdAt'],
    showProperties: [
      'id',
      'fullName',
      'email',
      'phone',
      'walletBalanceKobo',
      'referralCode',
      'referralEarningsKobo',
      'kycStatus',
      'emailVerified',
      'phoneVerified',
      'virtualAccountNumber',
      'virtualAccountBank',
      'createdAt',
      'updatedAt'
    ],
    editProperties: ['kycStatus', 'phoneVerified', 'emailVerified'],
    filterProperties: ['fullName', 'email', 'phone', 'kycStatus', 'createdAt'],
    properties: {
      pinHash: { isVisible: false },
      pinFailures: { isVisible: { list: false, show: true, edit: false, filter: false } },
      pinLockedUntil: { isVisible: { list: false, show: true, edit: false, filter: false } },
      walletBalanceKobo: { isVisible: { list: true, show: true, edit: false, filter: false } },
      referralEarningsKobo: { isVisible: { list: false, show: true, edit: false, filter: false } }
    },
    actions: {
      // Users are created by the app via Firebase sign-in, never directly by an admin.
      new: { isAccessible: false },
      // A user has related transactions — deleting would break the ledger. Deactivate
      // via kycStatus/support workflow instead of allowing hard deletes here.
      delete: { isAccessible: false },
      edit: {
        isAccessible: ({ currentAdmin }) =>
          !!currentAdmin && (currentAdmin as unknown as AdminSessionUser).role !== 'SUPPORT'
      },
      adjustWallet: {
        actionType: 'record',
        icon: 'DollarSign',
        component: Components.AdjustWallet,
        isAccessible: ({ currentAdmin }) => {
          const admin = currentAdmin as unknown as AdminSessionUser | undefined;
          return !!admin && (admin.role === 'SUPER_ADMIN' || admin.role === 'FINANCE');
        },
        handler: async (request, response, context) => {
          const { record, currentAdmin } = context;
          const admin = currentAdmin as unknown as AdminSessionUser | undefined;
          if (!record || !admin) {
            throw new Error('Missing record or admin context');
          }

          if (request.method !== 'post') {
            return { record: record.toJSON(currentAdmin) };
          }

          const { amount, direction, reason } = (request.payload ?? {}) as {
            amount?: string;
            direction?: 'credit' | 'debit';
            reason?: string;
          };

          try {
            if (!amount || Number(amount) <= 0) throw new Error('Enter an amount greater than zero');
            if (direction !== 'credit' && direction !== 'debit') throw new Error('Invalid direction');
            if (!reason || reason.trim().length < 5) {
              throw new Error('Reason must be at least 5 characters');
            }

            const result = await manualWalletAdjustment({
              userId: record.params.id as string,
              direction,
              amount: Number(amount),
              reason: reason.trim(),
              adminId: admin.id
            });

            await logAdminAction({
              adminId: admin.id,
              action: 'ADJUST_WALLET',
              targetType: 'User',
              targetId: record.params.id as string,
              metadata: {
                direction,
                amount,
                reason: reason.trim(),
                newBalanceKobo: result.balanceAfter.toString()
              }
            });

            return {
              record: record.toJSON(currentAdmin),
              notice: { message: 'Wallet adjusted successfully.', type: 'success' }
            };
          } catch (error) {
            return {
              record: record.toJSON(currentAdmin),
              notice: {
                message: error instanceof Error ? error.message : 'Adjustment failed',
                type: 'error'
              }
            };
          }
        }
      }
    }
  }
};
