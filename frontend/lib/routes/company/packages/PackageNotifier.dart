import 'package:flutter/cupertino.dart';
import 'package:frontend/models/package.dart';

class PackageNotifier extends ChangeNotifier {
  Map<String, Package> packages;

  PackageNotifier({required this.packages});

  List<Package> getPackages() {
    return packages.values.toList();
  }

  Package? getPackage(String id) {
    return packages[id];
  }

  void loadPackages(List<Package> packs) {
    for (Package p in packs) {
      packages[p.id] = p;
    }
  }

  void add(Package p) {
    if (!packages.containsKey(p.id)) {
      packages[p.id] = p;
      notifyListeners();
    }
  }

  void remove(Package p) {
    packages.remove(p.id);
    notifyListeners();
  }

  void edit(Package p) {
    if (packages.containsKey(p.id)) {
      packages[p.id] = p;
      notifyListeners();
    }
  }
}
