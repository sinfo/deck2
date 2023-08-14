import 'package:flutter/material.dart';
import 'package:frontend/components/EditableCard.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/services/companyService.dart';

class DetailsScreen extends StatelessWidget {
  final Company company;
  final _companyService = CompanyService();

  DetailsScreen({Key? key, required this.company}) : super(key: key);

  Future<void> _editCompany(
      BuildContext context, String updatedValue, bool isDescription) async {
    Company? c;
    if (isDescription) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Updating Description...',
                style: TextStyle(color: Colors.white))),
      );
      c = await _companyService.updateCompany(
          id: company.id, description: updatedValue);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Updating Site...',
                style: TextStyle(color: Colors.white))),
      );
      c = await _companyService.updateCompany(
          id: company.id, site: updatedValue);
    }

    if (c != null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Done', style: TextStyle(color: Colors.white)),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('An error occured.',
                style: TextStyle(color: Colors.white))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
          child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: EditableCard(
              title: 'Description',
              body: company.description ?? "",
              linkify: true,
              bodyEditedCallback: (newDescription) =>
                  _editCompany(context, newDescription, true),
              isSingleline: false,
              textInputType: TextInputType.multiline,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
            child: EditableCard(
              title: 'Site',
              body: company.site ?? "",
              linkify: true,
              bodyEditedCallback: (newSite) =>
                  _editCompany(context, newSite, false),
              isSingleline: false,
              textInputType: TextInputType.multiline,
            ),
          ),
        ],
      )),
    );
  }
}
