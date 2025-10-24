import type { ObjectID } from ".";

export interface BillingStatus {
  proForma: boolean;
  invoice: boolean;
  receipt: boolean;
  paid: boolean;
}

export interface Billing {
  id: ObjectID;
  status: BillingStatus;
  event: number;
  company?: ObjectID;
  value: number;
  invoiceNumber: string;
  emission: string;
  notes: string;
  visible: boolean;
}

export interface AllBillingsFilter {
  company?: ObjectID;
  event?: number;
  after?: string;
  before?: string;
  valueGreaterThan?: number;
  valueLessThan?: number;
}
