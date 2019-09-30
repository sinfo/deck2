export class Package {
    id: String;
    name: String;
    items: PackageItem[];
    price: Number;
    vat: Number;
}

export class PackageItem {
    item: String;
    quantity: Number;
    public: Boolean;
}
