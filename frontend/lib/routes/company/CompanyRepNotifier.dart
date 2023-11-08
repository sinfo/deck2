import 'package:flutter/cupertino.dart';
import 'package:frontend/components/status.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/models/participation.dart';

class CompanyRepNotifier extends ChangeNotifier {
  List<CompanyRep> reps;

  CompanyRepNotifier({required this.reps});

  void edit(CompanyRep s) {
    int index = reps.indexWhere((rep) => s.id == rep.id);
    if (index != -1) {
      reps[index] = s;
      notifyListeners();
    }
  }
}
