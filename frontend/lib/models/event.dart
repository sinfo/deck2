import 'dart:convert';

import 'package:frontend/models/item.dart';
import 'package:frontend/models/package.dart';
import 'package:frontend/services/itemService.dart';
import 'package:frontend/services/packageService.dart';
import 'package:intl/intl.dart';

class Event {
  final int id;
  final String name;
  final DateTime start;
  final DateTime end;
  final List<String>? itemIds;
  List<EventPackage> eventPackagesId = [];

  List<Item>? _items;

  ItemService _itemService = ItemService();

  Event({
    required this.id,
    required this.name,
    required this.start,
    required this.end,
    this.itemIds,
    required this.eventPackagesId,
  });

  Future<List<Item>?> get items async {
    if (_items != null && _items!.length > 0) {
      return _items;
    } else if (itemIds == null || itemIds == []) {
      return [];
    }

    List<Item> l = [];
    for (String itemID in itemIds!) {
      Item? t = await _itemService.getItem(itemID);
      if (t != null) {
        l.add(t);
      }
    }

    _items = l;
    return _items;
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    var evPackages = json['packages'] as List;
    return Event(
      id: json['id'],
      name: json['name'],
      start: DateTime.parse(json['begin']),
      end: DateTime.parse(json['end']),
      itemIds: List.from(json['items']),
      eventPackagesId: evPackages.map((e) => EventPackage.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'start': start,
        'end': end,
        'items': itemIds,
        'packages': eventPackagesId == null
            ? ""
            : eventPackagesId!.map((e) => e.toJson()).toList(),
      };

  @override
  String toString() {
    String repr = "";
    Map<String, dynamic> ev = this.toJson();
    ev.forEach((key, value) {
      repr += key + ' ';
      if (value != DateTime) {
        repr += value.toString();
      } else {
        repr += DateFormat('yyyy-MM-dd HH:mm').format(value);
      }
      repr += '\n';
    });
    return repr;
  }
}

class EventPublic {
  final int id;
  final String name;
  final DateTime start;
  final DateTime end;
  final List<String> themes;

  EventPublic({
    required this.id,
    required this.name,
    required this.start,
    required this.end,
    required this.themes,
  });

  factory EventPublic.fromJson(Map<String, dynamic> json) {
    return EventPublic(
      id: json['id'],
      name: json['name'],
      start: DateTime.parse(json['begin']),
      end: DateTime.parse(json['end']),
      themes: json['themes'] as List<String>,
    );
  }
}

class EventPackage {
  final String packageID;
  final String publicName;
  final bool available;

  PackageService _packageService = PackageService();
  Package? _package;

  EventPackage({
    required this.packageID,
    required this.publicName,
    required this.available,
  });

  Future<Package?> get package async {
    if (_package != null) {
      return _package;
    }

    _package = await _packageService.getPackage(packageID);
    return _package;
  }

  factory EventPackage.fromJson(Map<String, dynamic> json) {
    return EventPackage(
        packageID: json['template'],
        publicName: json['public_name'],
        available: json['available']);
  }

  Map<String, dynamic> toJson() => {
        'template': packageID,
        'public_name': publicName,
        'available': available,
      };

  @override
  String toString() {
    return json.encode(this.toJson());
  }
}
