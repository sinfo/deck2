import 'package:flutter/material.dart';
import 'package:frontend/components/status.dart';
import 'package:frontend/models/participation.dart';

class FilterBar extends StatefulWidget {
  final Function onSelected;

  FilterBar({Key? key, required this.onSelected}) : super(key: key);

  @override
  FilterBarState createState() => FilterBarState(onSelected: onSelected);
}

class FilterBarState extends State<FilterBar> {
  final Function onSelected;

  FilterBarState({Key? key, required this.onSelected});

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: rowChips(),
    );
  }

  rowChips() {
    List<Widget> filters = [];
    for (int i = 0; i < STATUSSTRING.length; i++) {
      filters.add(createChip(STATUSFILTER.entries.elementAt(i).key, i));
    }
    return Row(children: filters);
  }

  Widget createChip(ParticipationStatus status, int index) {
    String label = STATUSSTRING[status]!;
    return Container(
      margin: EdgeInsets.all(7.0),
      child: ChoiceChip(
        selected: _currentIndex == index,
        backgroundColor: Colors.indigo[100],
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.black12, width: 1),
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 1,
        pressElevation: 3,
        shadowColor: Colors.teal,
        selectedColor: STATUSCOLOR[status],
        onSelected: (bool selected) {
          setState(() {
            _currentIndex = selected ? index : _currentIndex;
            onSelected(status);
          });
        },
        label: Text(
          label == '' ? 'All' : label,
        ),
        labelStyle: TextStyle(
          color: _currentIndex != index
              ? Colors.indigo[400]
              : STATUSTEXTCOLOR[status],
        ),
        padding: EdgeInsets.all(6.0),
      ),
    );
  }
}
