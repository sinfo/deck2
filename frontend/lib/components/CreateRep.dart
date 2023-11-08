import 'package:flutter/material.dart';
import 'package:frontend/components/DisplayContact_Company.dart';
import 'package:frontend/models/contact.dart';
import 'package:frontend/services/companyService.dart';
import 'package:frontend/services/companyRepService.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/components/EditContact.dart';
import 'package:frontend/components/DisplayContact2.dart';
import 'package:frontend/components/DisplayContact_Company.dart';
import 'package:frontend/routes/company/CompanyRepNotifier.dart';
import 'package:frontend/services/authService.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'InformationBox.dart';

class CreateRep extends StatefulWidget {
  Company company;

  CreateRep({Key? key, required this.company}) : super(key: key);

  @override
  _CreateRepState createState() => _CreateRepState();
}

class _CreateRepState extends State<CreateRep> {
  CompanyService companyService = new CompanyService();
  CompanyRepService companyRepService = new CompanyRepService();

  List<CompanyRep> representatives = [];

  @override
  void initState() {
    super.initState();
  }

  /* Future<void> repChangedCallback(BuildContext context,
      {Future<CompanyRep?>? fr, CompanyRep? rep}) async {
    String? r;
    if (fr != null) {
      r = await fr;
    } else if (rep != null) {
      r = rep;
    }
    if (r != null) {
      context.read<CompanyRepNotifier>().edit(r);
      setState(() {
        widget.company.employees?.last = r!;
      });
    }
  }*/
  Contact? cont = null;
  String? _repId = null;
  // Function to create a company representative
  Future<void> _createCompanyRep() async {
    // Declare repName before the showDialog.
    String repName = '';

    await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Create Representative'),
          content: TextField(
            decoration: InputDecoration(labelText: 'Name'),
            onChanged: (value) {
              repName = value; // Update the repName variable as you type.
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (repName.isNotEmpty) {
                  if (repName.isNotEmpty) {
                    try {
                      print(repName);
                      Company? _company;
                      _company = await companyService.createRep(
                          id: widget.company.id, name: repName, contact: cont);
                      print(_company!.employees!.last);
                      CompanyRep _newRep;
                      _newRep = await companyRepService
                          .getCompanyRep(_company.employees!.last);
                      _repId = await _newRep.id;
                      cont = await _newRep.contact;
                      if (_company.employees != null &&
                          _company.employees!.isNotEmpty) {
                        setState(() {
                          // Add the new representative to the list
                          representatives.add(_newRep);
                        });
                        print(_company.employees!.last);
                        print(_newRep);

                        // Close the dialog.
                        Navigator.of(context).pop();
                      } else {
                        print('Error: _company is null after createRep.');
                      }

                      print(repName);
                      print(representatives);
                    } catch (e) {
                      // Handle any errors that occur during representative creation
                      print('Error creating representative: $e');
                    }
                  }
                }
              },
              child: Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _deleteCompanyRep(int index) async {
    if (index >= 0 && index < representatives.length) {
      // Remove the representative at the specified index
      representatives.removeAt(index);
      Company? _company;

      _company = await companyService.deleteRep(
          id: widget.company.id, repId: representatives[index].id);
    } else {
      print('Index is out of range or the list is empty.');
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color.fromRGBO(186, 196, 242, 0.1),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Add a button to create a company representative
            FloatingActionButton(
              onPressed: _createCompanyRep,
              tooltip: 'Create Representative',
              child: Icon(Icons.person_add),
              backgroundColor: Color(0xff5C7FF2),
            ),
            SizedBox(height: 10),
            //_isEditable(cont), // Edit Contacts button
          ],
        ),
        body: FutureBuilder(
            future:
                companyRepService.getCompanyReps(null, widget.company.id, null),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                print(snapshot.error);
                ScaffoldMessenger.of(context).hideCurrentSnackBar();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'An error has occured. Please contact the admins',
                        style: TextStyle(color: Colors.white)),
                    duration: Duration(seconds: 4),
                  ),
                );
                return Center(
                    child: Icon(
                  Icons.error,
                  size: 200,
                ));
              }

              if (snapshot.hasData) {
                print("Id company: " + widget.company.id);
                representatives = snapshot.data as List<CompanyRep>;
                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        physics: BouncingScrollPhysics(),
                        itemCount: representatives.length,
                        itemBuilder: (context, index) {
                          final representative = representatives[index];
                          return ListTile(
                            leading: Icon(Icons
                                .person), // Add your representative image here
                            title: Text(representative.name ?? 'N/A'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () async {
                                    // Implement code to edit the representative's details
                                    // You can use the representative data to populate the edit form
                                    final bool? shouldRefresh =
                                        await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => EditContact(
                                              contact: cont!,
                                              person: widget.company)),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () {
                                    // Delete the representative when the delete icon is tapped
                                    _deleteCompanyRep(index);
                                    print(index);
                                    print(representatives.length);
                                    print(representatives[index].id);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              } else {
                return Container();
              }
            }));
  }
}
