import 'package:flutter/widgets.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/event.dart';

class EventNotifier with ChangeNotifier {
  Event _event;

  EventNotifier(this._event);

  Event get event => _event;
  set event(Event e) {
    _event = e;
    App.localStorage.setInt("event", _event.id);
    notifyListeners();
  }
}
