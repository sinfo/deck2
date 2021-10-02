import 'package:flutter/material.dart';
import 'package:frontend/components/generalSearchDelegate.dart';

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
  @override
  Widget build(BuildContext context) {
    return AppBar(
        title: TextField(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              filled: true,
              fillColor: Colors.white,
              hintText: 'Search Company, Speaker or Member',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (newQuery) {
              showSearch(
                  context: context,
                  delegate: GeneralSearchDelegate(),
                  query: newQuery);
            }));
  }
}
