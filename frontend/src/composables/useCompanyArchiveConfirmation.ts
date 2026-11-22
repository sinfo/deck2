import { inject, type InjectionKey } from "vue";

export const companyArchiveConfirmationKey: InjectionKey<() => boolean> = Symbol(
  "companyArchiveConfirmation",
);

export const useCompanyArchiveConfirmation = () =>
  inject(companyArchiveConfirmationKey, () => true);
