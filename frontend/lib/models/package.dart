import 'dart:convert';
import 'package:frontend/models/item.dart';

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'items': jsonEncode(items),
        'price': price,
        'vat': vat
      };

  @override
  String toString() {
    return json.encode(this.toJson());
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

  Map<String, dynamic> toJson() => {
        'item': item,
        'quantity': quantity,
        'public': public,
      };

  @override
  String toString() {
    return json.encode(this.toJson());
  }
}

class PackageItemPublic {
  final Item? item;
  final int? quantity;

  PackageItemPublic({
    this.item,
    this.quantity,
  });

  factory PackageItemPublic.fromJson(Map<String, dynamic> json) {
    return PackageItemPublic(
      item: Item.fromJson(json['item']),
      quantity: json['quantity'],
    );
  }

  Map<String, dynamic> toJson() => {
        'item': item,
        'quantity': quantity,
      };

  @override
  String toString() {
    return json.encode(this.toJson());
  }
}

class PackagePublic {
  final String? name;
  final List<PackageItemPublic>? items;

  PackagePublic({
    this.name,
    this.items,
  });

  factory PackagePublic.fromJson(Map<String, dynamic> json) {
    var items = json['items'] as List;
    return PackagePublic(
      name: json['name'],
      items: items.map((e) => PackageItemPublic.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'items': jsonEncode(items),
      };

  @override
  String toString() {
    return json.encode(this.toJson());
  }
}
