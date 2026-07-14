import { ComponentLoader } from 'adminjs';

export const componentLoader = new ComponentLoader();

export const Components = {
  AdjustWallet: componentLoader.add('AdjustWallet', './components/adjust-wallet')
};
