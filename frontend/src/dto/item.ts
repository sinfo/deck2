export interface Item {
  id: string;
  name: string;
  type?: string;
  img?: string;
  description?: string;
  price?: number; // cents
  vat?: number; // percent
}

// Payload used when creating a new item (no id)
export type CreateItemPayload = Omit<Item, "id">;

// Payload used when updating an item
export type UpdateItemPayload = Partial<Omit<Item, "id">> & { id: string };
