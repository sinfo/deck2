import 'package:flutter/material.dart';
import 'package:frontend/components/blurryDialog.dart';
import 'package:frontend/models/contact.dart';
import 'package:frontend/services/companyService.dart';
import 'package:frontend/services/companyRepService.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/components/EditContact.dart';
import 'package:frontend/components/DisplayContactCompany.dart';
import 'package:frontend/routes/company/CompanyTableNotifier.dart';
import 'package:frontend/services/authService.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class CreateRep extends StatefulWidget {
  Company company;

  CreateRep({Key? key, required this.company}) : super(key: key);

  @override
  _CreateRepState createState() => _CreateRepState();
}

class _CreateRepState extends State<CreateRep> {
  CompanyService companyService = new CompanyService();
  CompanyRepService companyRepService = new CompanyRepService();
  late List<CompanyRep> _Reps = [];

  @override
  void initState() {
    super.initState();
  }

  Future<void> companyChangedCallback(BuildContext context,
      {Future<Company?>? fs, Company? company}) async {
    Company? s;
    if (fs != null) {
      s = await fs;
    } else if (company != null) {
      s = company;
    }

    if (s != null) {
      Provider.of<CompanyTableNotifier>(context, listen: false).edit(s);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Done.', style: TextStyle(color: Colors.white))),
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

  Contact? cont = null;
  String repName = '';

// Function to create a company representative
  Future<void> createCompanyRep(
      String repName, Company company, BuildContext context) async {
    try {
      Company? _company = await companyService.createRep(
        id: company.id,
        name: repName,
        contact: cont,
      );

      setState(() {
        // Add the new representative to the list
        companyChangedCallback(context, company: _company);
      });

      // Close the dialog or navigate back to the previous screen if applicable
      Navigator.of(context).pop();
    } catch (e) {
      print('Error creating representative: $e');
    }
  }

  void _deleteCompanyRep(
      BuildContext context, CompanyRep representative) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this representative?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(); // Close the dialog without deleting
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_Reps.contains(representative)) {
                  _Reps.remove(representative);
                  Company? _company = await companyService.deleteRep(
                      id: widget.company.id, repId: representative.id);
                  CompanyTableNotifier notifier =
                      Provider.of<CompanyTableNotifier>(context, listen: false);
                  notifier.edit(_company!);
                  // Trigger a rebuild of the widget tree to update the UI
                  setState(() {
                    companyChangedCallback(context, company: _company);
                  });

                  Navigator.of(context)
                      .pop(); // Close the dialog before deletion
                } else {
                  print('Representative not found in the list.');
                }
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Consumer<CompanyTableNotifier>(builder: (context, notif, child) {
      return Scaffold(
          backgroundColor: Color.fromRGBO(186, 196, 242, 0.1),
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Add a button to create a company representative
              FloatingActionButton(
                onPressed: () {
                  showDialog<String>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('Create Representative'),
                        content: TextField(
                          decoration: InputDecoration(labelText: 'Name'),
                          onChanged: (value) {
                            repName =
                                value; // Update the repName variable as you type.
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
                            onPressed: () {
                              // Call the function to create the representative
                              createCompanyRep(
                                  repName, widget.company, context);
                            },
                            child: Text('Create'),
                          ),
                        ],
                      );
                    },
                  );
                },
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
                  companyRepService.getCompanyReps(company: widget.company.id),
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
                  _Reps = snapshot.data as List<CompanyRep>;
                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          physics: BouncingScrollPhysics(),
                          itemCount: _Reps.length,
                          key: UniqueKey(),
                          itemBuilder: (context, index) {
                            final representative = _Reps[index];
                            return ListTile(
                              key: Key(representative.id.toString()),
                              leading: Icon(Icons
                                  .person), // Add your representative image here
                              title: Text(representative.name ?? 'N/A'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit),
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              DisplayContactsCompany(
                                                  rep: representative),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () {
                                      // Delete the representative when the delete icon is tapped
                                      _deleteCompanyRep(
                                          context, representative);
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
    });
  }
}
