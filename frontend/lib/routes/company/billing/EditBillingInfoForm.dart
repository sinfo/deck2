import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/services/companyService.dart';

class EditBillingInfoForm extends StatefulWidget {
  final CompanyBillingInfo? billingInfo;
  final String id;
  final void Function(CompanyBillingInfo) onBillingInfoEdit;
  EditBillingInfoForm(
      {Key? key,
      required this.billingInfo,
      required this.onBillingInfoEdit,
      required this.id})
      : super(key: key);

  @override
  _EditBillingInfoFormState createState() => _EditBillingInfoFormState();
}

class _EditBillingInfoFormState extends State<EditBillingInfoForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _tinController;

  final _companyService = CompanyService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.billingInfo!.name);
    _addressController =
        TextEditingController(text: widget.billingInfo!.address);
    _tinController = TextEditingController(text: widget.billingInfo!.tin);
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      var name = _nameController.text;
      var address = _addressController.text;
      var tin = _tinController.text;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Updating Billing Info...')),
      );

      CompanyBillingInfo bi =
          new CompanyBillingInfo(name: name, address: address, tin: tin);

      Company? c =
          await _companyService.updateCompany(id: widget.id, billingInfo: bi);

      if (c != null) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        widget.onBillingInfoEdit(bi);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Done'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
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
    return _buildForm();
  }
}
