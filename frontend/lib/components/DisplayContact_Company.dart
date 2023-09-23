import 'package:flutter/material.dart';
import 'package:frontend/models/contact.dart';
import 'package:frontend/services/companyService.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/components/EditContact.dart';
import 'package:frontend/components/DisplayContact2.dart';
import 'package:frontend/services/authService.dart';
import 'package:provider/provider.dart';
import 'InformationBox.dart';

class DisplayContactsCompany extends StatefulWidget {
  final Company company;

  DisplayContactsCompany({Key? key, required this.company}) : super(key: key);

  @override
  _DisplayContactsState createState() => _DisplayContactsState();
}

class _DisplayContactsState extends State<DisplayContactsCompany> {
  List<CompanyRep> representatives = [];

  @override
  void initState() {
    super.initState();
    representatives = widget.company.employees ?? [];
  }

  // Function to create a company representative
  Future<void> _createCompanyRep() async {
    // Declare repName before the showDialog.
    String? repName = '';

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
              onPressed: () {
                if (repName != null && repName!.isNotEmpty) {
                  try {
                    // Create a CompanyRep object with id and name.
                    CompanyRep newRep = CompanyRep(
                      id: widget.company.id, // Use the company's ID
                      name: repName,
                      contactID: '', // You can leave contactID empty for now.
                    );

                    setState(() {
                      // Add the new representative to the list
                      representatives.add(newRep);
                    });
                    print(repName);
                    print(representatives);
                    // Close the dialog.
                    Navigator.of(context).pop();
                  } catch (e) {
                    // Handle any errors that occur during representative creation
                    print('Error creating representative: $e');
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

  // Function to delete a company representative
  void _deleteCompanyRep(int index) {
    setState(() {
      // Remove the representative at the specified index
      representatives.removeAt(index);
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(186, 196, 242, 0.1),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 32),
              physics: BouncingScrollPhysics(),
              itemCount: representatives.length,
              itemBuilder: (context, index) {
                final representative = representatives[index];
                return ListTile(
                  leading:
                      Icon(Icons.person), // Add your representative image here
                  title: Text(representative.name ?? 'N/A'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          // Implement code to edit the representative's details
                          // You can use the representative data to populate the edit form
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => DisplayContacts(
                                person: representative,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          // Delete the representative when the delete icon is tapped
                          _deleteCompanyRep(index);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
    );
  }
}
