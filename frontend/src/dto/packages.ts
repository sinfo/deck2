import type { ObjectID } from ".";

export interface PackageItem {
  item: ObjectID;
  quantity: number;
  public: boolean;
}

export interface Package {
  id: ObjectID;
  name: string;
  items: PackageItem[];
  price: number;
  vat: number;
}

export interface PackageItemPublic {
  item: ObjectID;
  quantity: number;
}

export interface PackagePublic {
  name: string;
  items: PackageItemPublic[];
}
