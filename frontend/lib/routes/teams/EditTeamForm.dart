import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/models/team.dart';
import 'package:frontend/services/teamService.dart';

class EditTeamForm extends StatefulWidget {
  Team team;
  final void Function(BuildContext, Team?) onEdit;
  EditTeamForm({Key? key, required this.team, required this.onEdit})
      : super(key: key);

  @override
  _EditTeamFormState createState() => _EditTeamFormState();
}

class _EditTeamFormState extends State<EditTeamForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  TeamService _teamService = new TeamService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.team.name);
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      var name = _nameController.text;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading')),
      );

      Team? t = await _teamService.updateTeam(widget.team.id!, name);

      if (t != null) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Done'),
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.pop(context);
        print("a imprimir t");
        print(t);
        widget.onEdit(context, t);
        print("chamou onEdit no form");
      } else {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occured.')),
        );
      }
    }
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _nameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
              decoration: InputDecoration(
                icon: const Icon(Icons.person),
                labelText: "Name *",
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text("CANCEL",
                    style: TextStyle(
                        fontSize: 14, color: Theme.of(context).accentColor)),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: Theme.of(context).accentColor,
                    padding: EdgeInsets.symmetric(horizontal: 50),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () => _submit(),
                  child: const Text('SUBMIT'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar(
          disableEventChange: true,
        ),
        body: LayoutBuilder(builder: (contex, constraints) {
          return Column(children: [
            _buildForm(),
          ]);
        }));
  }
}
