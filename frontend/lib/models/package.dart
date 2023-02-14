import 'dart:convert';

import 'package:frontend/models/item.dart';
import 'package:frontend/services/itemService.dart';

class Package {
  final String id;
  final String name;
  final List<PackageItem>? items;
  final int price;
  final int vat;

  Package({
    required this.id,
    required this.name,
    this.items,
    required this.price,
    required this.vat,
  });

  factory Package.fromJson(Map<String, dynamic> json) {
    var items = json['items'] == null ? [] : json['items'] as List;
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
        'items': items == null ? null : items!.map((item) => item.toJson()).toList(),
        'price': price,
        'vat': vat
      };

  @override
  String toString() {
    String repr = "";
    Map<String, dynamic> pack = this.toJson();
    pack.forEach((key, value) {
      repr += key + ' ';
      if (value != List) {
        repr += value.toString();
      }
      repr += '\n';
    });
    return repr;
  }
}

class PackageItem {
  final String itemID;
  final int? quantity;
  final bool? public;

  ItemService _itemService = ItemService();
  Item? _item;

  PackageItem({
    required this.itemID,
    this.quantity,
    this.public,
  });

  Future<Item?> get item async {
    if (_item != null) {
      return _item;
    }

    _item = await _itemService.getItem(itemID);
    return _item;
  }

  factory PackageItem.fromJson(Map<String, dynamic> json) {
    return PackageItem(
      itemID: json['item'],
      quantity: json['quantity'],
      public: json['public'],
    );
  }

  Map<String, dynamic> toJson() => {
        'item': itemID,
        'quantity': quantity,
        'public': public,
      };

  @override
  String toString() {
    return json.encode(this.toJson());
  }
}

class PackageItemPublic {
  final String itemID;
  final int? quantity;

  PackageItemPublic({
    required this.itemID,
    this.quantity,
  });

  factory PackageItemPublic.fromJson(Map<String, dynamic> json) {
    return PackageItemPublic(
      itemID: json['item'],
      quantity: json['quantity'],
    );
  }

  Map<String, dynamic> toJson() => {
        'item': itemID,
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
        'items': items == null ? "" : items!.map((e) => e.toJson()).toList(),
      };

  @override
  String toString() {
    return json.encode(this.toJson());
  }
}
