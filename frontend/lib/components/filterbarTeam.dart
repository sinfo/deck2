import 'package:flutter/material.dart';

class FilterBarTeam extends StatefulWidget {
  final Function onSelected;

  FilterBarTeam({Key? key, required this.onSelected}) : super(key: key);

  @override
  FilterBarTeamState createState() => FilterBarTeamState(onSelected: onSelected);
}

class FilterBarTeamState extends State<FilterBarTeam> {
  final Function onSelected;

  FilterBarTeamState({Key? key, required this.onSelected});

  int _currentIndex = 0;
  List<String> _filters = [
    "All",
    "Coordination",
    "DevTeam",
    "Logistics",
    "Multimedia",
    "Partnerships",
    "Social Network",
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: rowChips(),
    );
  }

  rowChips() {
    List<Widget> filters = [];
    for (int i = 0; i < _filters.length; i++) {
      filters.add(createChip(_filters[i], i));
    }
    return Row(children: filters);
  }

  Widget createChip(String label, int index) {
    return Container(
      margin: EdgeInsets.all(7.0),
      child: ChoiceChip(
        selected: _currentIndex == index,
        backgroundColor: Colors.indigo[100],
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.black12, width: 1),
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 2,
        pressElevation: 1,
        shadowColor: Colors.teal,
        selectedColor: Colors.indigo[400],
        onSelected: (bool selected) {
          setState(() {
            _currentIndex = selected ? index : _currentIndex;
            onSelected(_filters[_currentIndex].toUpperCase());
          });
        },
        label: Text(label),
        labelStyle: TextStyle(
          color: _currentIndex != index ? Colors.indigo[400] : Colors.white,
        ),
        padding: EdgeInsets.all(6.0),
      ),
    );
  }
}
