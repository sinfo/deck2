import 'package:flutter/cupertino.dart';
import 'package:frontend/models/package.dart';

class PackageNotifier extends ChangeNotifier {
  List<Package> packages;

  PackageNotifier({required this.packages});

  List<Package> getPackages() {
    return packages;
  }

  void add(Package p) {
    int index = packages.indexWhere((package) => p.id == package.id);
    if (index == -1) {
      packages.add(p);
      notifyListeners();
    }
  }

  void remove(Package p) {
    packages.removeWhere((package) => p.id == package.id);
    notifyListeners();
  }

  void edit(Package p) {
    int index = packages.indexWhere((package) => p.id == package.id);
    if (index != -1) {
      packages[index] = p;
      notifyListeners();
    }
  }
}
