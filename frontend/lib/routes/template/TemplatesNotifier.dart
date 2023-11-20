import 'package:flutter/cupertino.dart';
import 'package:frontend/models/template.dart';

class TemplatesNotifier extends ChangeNotifier {
  List<Template> templates;

  TemplatesNotifier({required this.templates});

  List<Template> getAll() {
    return templates;
  }

  void add(Template t) {
    templates.add(t);
    notifyListeners();
  }

  void remove(Template t) {
    templates.removeWhere((template) => t.id == template.id);
    notifyListeners();
  }

  void edit(Template t) {
    int index = templates.indexWhere((template) => t.id == template.id);
    if (index != -1) {
      templates[index] = t;
      notifyListeners();
    }
  }
}
