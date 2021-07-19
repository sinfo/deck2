import 'dart:convert';

class Item {
  final String id;
  final String name;
  final String type;
  final String description;
  final String image;
  final int price;
  final int vat;

  Item({required this.id, required this.name, required this.type, required this.description, required this.image, required this.price, required this.vat});

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      description: json['description'],
      image: json['img'],
      price: json['price'],
      vat: json['vat'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'description': description,
        'img': image,
        'price': price,
        'vat': vat,
  };

  @override
  String toString() {
    return json.encode(this.toJson());
  }
}
