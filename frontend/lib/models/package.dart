class Package {
  final String? id;
  final String? name;
  final List<PackageItem>? items;
  final int? price;
  final int? vat;

  Package({
    this.id,
    this.name,
    this.items,
    this.price,
    this.vat,
  });

  factory Package.fromJson(Map<String, dynamic> json) {
    var items = json['items'] as List;
    return Package(
      id: json['id'],
      name: json['name'],
      items: items.map((e) => PackageItem.fromJson(e)).toList(),
      price: json['price'],
      vat: json['vat'],
    );
  }
}

class PackageItem {
  final Item? item;
  final int? quantity;
  final bool? public;

  PackageItem({
    this.item,
    this.quantity,
    this.public,
  });

  factory PackageItem.fromJson(Map<String, dynamic> json) {
    return PackageItem(
      item: Item.fromJson(json['item']),
      quantity: json['quantity'],
      public: json['public'],
    );
  }
}

class Item {
  final String? id;
  final String? name;
  final String? type;
  final String? description;
  final String? image;
  final int? price;
  final int? vat;

  Item({
    this.id,
    this.name,
    this.type,
    this.description,
    this.image,
    this.price,
    this.vat,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      description: json['description'],
      image: json['image'],
      price: json['price'],
      vat: json['vat'],
    );
  }
}
