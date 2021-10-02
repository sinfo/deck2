import 'package:flutter/widgets.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/event.dart';

class EventNotifier with ChangeNotifier {
  Event _event;
  Event _latest;

  EventNotifier(this._event, this._latest);

  bool get isLatest => _latest.id == _event.id;

  Event get latest => _latest;
  Event get event => _event;
  set event(Event e) {
    _event = e;
    App.localStorage.setInt("event", _event.id);
    notifyListeners();
  }
}