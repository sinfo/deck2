export interface Item {
  id: string;
  name: string;
  type?: string;
  description?: string;
  img?: string;
  price?: number; // cents
  vat?: number; // percent
}
