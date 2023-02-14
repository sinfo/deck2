import 'package:flutter/cupertino.dart';
import 'package:frontend/models/item.dart';

class ItemsNotifier extends ChangeNotifier {
  List<Item> items;

  ItemsNotifier({required this.items});

  List<Item> getItems() {
    return items;
  }

  void add(Item i) {
    items.add(i);
    notifyListeners();
  }

  void remove(Item i) {
    items.removeWhere((item) => i.id == item.id);
    notifyListeners();
  }

  void edit(Item i) {
    int index = items.indexWhere((item) => i.id == item.id);
    if (index != -1) {
      items[index] = i;
      notifyListeners();
    }
  }
}
