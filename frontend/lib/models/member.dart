import 'package:flutter/widgets.dart';

class Member {
  final String id;
  final String name;
  final String sinfoId;
  final String image;

  Member({this.id, this.name, this.sinfoId, this.image});

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'],
      name: json['name'],
      sinfoId: json['sinfoID'],
      image: json['img'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sinfoID': sinfoId,
        'img': image,
      };
}
