import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/routes/company/CompanyTableNotifier.dart';
import 'package:frontend/services/companyService.dart';
import 'package:provider/provider.dart';

class AddBillingInfoForm extends StatefulWidget {
  final String id;
  final void Function(CompanyBillingInfo) onBillingInfoEdit;

  AddBillingInfoForm({Key? key, required this.id, required this.onBillingInfoEdit})
      : super(key: key);

  @override
  _AddBillingInfoFormState createState() => _AddBillingInfoFormState();
}

class _AddBillingInfoFormState extends State<AddBillingInfoForm> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _tinController = TextEditingController();

  final _companyService = CompanyService();

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      var name = _nameController.text;
      var address = _addressController.text;
      var tin = _tinController.text;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Creating Billing Info...')),
      );

      CompanyBillingInfo bi =
          new CompanyBillingInfo(name: name, address: address, tin: tin);

      Company? c =
          await _companyService.updateCompany(id: widget.id, billingInfo: bi);

      if (c != null) {
        CompanyTableNotifier notifier =
            Provider.of<CompanyTableNotifier>(context, listen: false);
        notifier.edit(c);

        widget.onBillingInfoEdit(bi);

        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Done'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occured.')),
        );
      }
      Navigator.pop(context);
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
                  return 'Please enter the name of billing info';
                }
                return null;
              },
              decoration: const InputDecoration(
                icon: const Icon(Icons.title),
                labelText: "Billing Info name *",
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _addressController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the address of billing info';
                }
                return null;
              },
              decoration: const InputDecoration(
                icon: const Icon(Icons.title),
                labelText: "Billing Info address *",
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _tinController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the tin (NIF/Contribuinte) of billing info';
                }
                return null;
              },
              decoration: const InputDecoration(
                icon: const Icon(Icons.title),
                labelText: "Billing Info tin (NIF/Contribuinte) *",
              ),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () => _submit(),
              child: const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    CustomAppBar appBar = CustomAppBar(
      disableEventChange: true,
    );
    return Scaffold(
      body: Stack(children: [
        Container(
            margin: EdgeInsets.fromLTRB(0, appBar.preferredSize.height, 0, 0),
            child: _buildForm()),
        appBar,
      ]),
    );
  }
}
