import 'package:flutter/material.dart';

class FilterBarTeam extends StatefulWidget {
  String currentFilter;
  final Function onSelected;
  final List<String> teamFilters;

  FilterBarTeam(
      {Key? key,
      required this.currentFilter,
      required this.teamFilters,
      required this.onSelected})
      : super(key: key);

  @override
  FilterBarTeamState createState() => FilterBarTeamState(
      currentFilter: currentFilter,
      teamFilters: teamFilters,
      onSelected: onSelected);
}

class FilterBarTeamState extends State<FilterBarTeam> {
  String currentFilter;
  final List<String> teamFilters;
  final Function onSelected;

  FilterBarTeamState(
      {Key? key,
      required this.currentFilter,
      required this.teamFilters,
      required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: rowChips(),
    );
  }

  rowChips() {
    List<Widget> filters = [];
    for (int i = 0; i < teamFilters.length; i++) {
      filters.add(createChip(teamFilters[i], i));
    }
    return Row(children: filters);
  }

  Widget createChip(String label, int index) {
    return Container(
      margin: EdgeInsets.all(7.0),
      child: ChoiceChip(
        selected: label.toLowerCase() == currentFilter.toLowerCase(),
        backgroundColor: Colors.indigo[100],
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.black12, width: 1),
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 1,
        pressElevation: 3,
        shadowColor: Colors.teal,
        selectedColor: Colors.indigo[400],
        onSelected: (bool selected) {
          setState(() {
            onSelected(label.toUpperCase());
          });
        },
        label: Text(label),
        labelStyle: TextStyle(
          color: label.toLowerCase() != currentFilter.toLowerCase()
              ? Colors.indigo[400]
              : Colors.white,
        ),
        padding: EdgeInsets.all(6.0),
      ),
    );
  }
}
