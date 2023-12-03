import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:frontend/models/flightInfo.dart';

class FlightsNotifier extends ChangeNotifier {
  List<FlightInfo> flights;

  FlightsNotifier({required this.flights});

  void add(FlightInfo flight) {
    flights.add(flight);
    notifyListeners();
  }

  void remove(FlightInfo flight) {
    flights.remove(flight);
    notifyListeners();
  }

  void edit(FlightInfo flight) {
    int index = flights.indexWhere((element) => element.id == flight.id);
    if (index != -1) {
      flights[index] = flight;
      notifyListeners();
    }
  }

  List<FlightInfo> getUpcoming() {
    return flights
      .where((element) => element.inbound.isAfter(DateTime.now()))
      .sorted((a, b) => a.inbound.compareTo(b.inbound))
      .toList();
  }

  List<FlightInfo> getPast() {
    return flights
      .where((element) => element.inbound.isBefore(DateTime.now()))
      .sorted((a, b) => b.inbound.compareTo(a.inbound))
      .reversed
      .toList();
  }

  List<FlightInfo> getOnGoing() {
    return flights.where((element) => element.outbound.isBefore(DateTime.now()) && element.inbound.isAfter(DateTime.now())).toList();
  }
}
