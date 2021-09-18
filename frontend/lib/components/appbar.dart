import 'package:flutter/material.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/event.dart';
import 'package:frontend/services/eventService.dart';
import 'package:provider/provider.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  CustomAppBar({Key? key})
      : preferredSize = Size.fromHeight(kToolbarHeight),
        super(key: key);

  @override
  final Size preferredSize;

  @override
  _CustomAppBarState createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  EventService _eventService = EventService();
  late Future<List<int>> _eventIds;

  @override
  void initState() {
    super.initState();
    _eventIds = _eventService.getEventIds();
  }

  @override
  Widget build(BuildContext context) {
    EventNotifier notifier = Provider.of<EventNotifier>(context);
    int current = notifier.event.id;
    return AppBar(
      title: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              child: Image.asset(
                'assets/logo-branco2.png',
                height: 100,
                width: 100,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FutureBuilder(
              future: _eventIds,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  List<int> ids = snapshot.data as List<int>;
                  return DropdownButton<int>(
                    icon: const Icon(
                      Icons.arrow_downward,
                      color: Colors.white,
                    ),
                    iconSize: 24,
                    elevation: 16,
                    dropdownColor: Colors.grey,
                    style: const TextStyle(color: Colors.white),
                    underline: Container(
                      height: 2,
                      color: Colors.white,
                    ),
                    onChanged: (int? newId) async {
                      if (newId == null || newId == current) {
                        return;
                      } else {
                        Event newEvent =
                            await _eventService.getEvent(eventId: newId);
                        notifier.event = newEvent;
                      }
                    },
                    value: current,
                    items: ids
                        .map<DropdownMenuItem<int>>((e) =>
                            DropdownMenuItem<int>(
                                value: e, child: Text('SINFO ${e.toString()}')))
                        .toList(),
                  );
                } else {
                  return Container();
                }
              },
            ),
          )
        ],
      ),
    );
  }
}
