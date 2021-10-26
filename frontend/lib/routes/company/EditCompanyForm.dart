import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/services/companyService.dart';
import 'package:frontend/services/speakerService.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class EditCompanyForm extends StatefulWidget {
  final Company company;
  final void Function(BuildContext, Company?) onEdit;
  EditCompanyForm({Key? key, required this.company, required this.onEdit})
      : super(key: key);

  @override
  _EditCompanyFormState createState() => _EditCompanyFormState();
}

class _EditCompanyFormState extends State<EditCompanyForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  final _companyService = CompanyService();
  final _imagePicker = ImagePicker();
  XFile? _image;
  int? _size;
  String? _prevImage;
  late DropzoneViewController _controller;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.company.name);
    _prevImage = widget.company.companyImages.internal;
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      var name = _nameController.text;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading')),
      );

      Company? s = await _companyService.updateCompany(
        id: widget.company.id,
        name: name,
        billingInfo: widget.company.billingInfo,
        description: widget.company.description,
        site: widget.company.site,
      );
      if (s != null && _image != null) {
        s = kIsWeb
            ? await _companyService.updateInternalImageWeb(
                id: s.id, image: _image!)
            : await _companyService.updateInternalImage(
                id: s.id, image: File(_image!.path));
      }
      if (s != null) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Done'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
        widget.onEdit(context, s);
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
              decoration: const InputDecoration(
                icon: const Icon(Icons.work),
                labelText: "Name *",
              ),
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

  Widget _buildPicture(double size) {
    Widget inkWellChild;

    if (_image == null && _prevImage == null) {
      inkWellChild = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              size: size / 3,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Click to upload or drag and drop image",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  )),
            ),
          ],
        ),
      );
    } else {
      String path = _image == null ? _prevImage! : _image!.path;
      inkWellChild = Center(
        child: kIsWeb
            ? Image.network(
                path,
                fit: BoxFit.fill,
              )
            : Image.file(
                File(path),
                fit: BoxFit.fill,
              ),
      );
    }

    Widget outerBox;

    if (kIsWeb) {
      outerBox = Padding(
        padding: const EdgeInsets.all(8.0),
        child: DottedBorder(
          child: SizedBox(
            width: size,
            height: size,
            child: InkWell(
              child: Stack(children: [
                DropzoneView(
                  operation: DragOperation.copy,
                  onCreated: (controller) => this._controller = controller,
                  cursor: CursorType.grab,
                  onDrop: _acceptFile,
                ),
                inkWellChild,
              ]),
              onTap: () {
                _pickImage();
              },
            ),
          ),
          strokeWidth: 1,
        ),
      );
    } else {
      outerBox = Padding(
        padding: const EdgeInsets.all(8.0),
        child: DottedBorder(
          child: SizedBox(
            width: size,
            height: size,
            child: InkWell(
              child: inkWellChild,
              onTap: () {
                _pickImage();
              },
            ),
          ),
          strokeWidth: 1,
        ),
      );
    }

    return outerBox;
  }

  _acceptFile(dynamic event) async {
    final name = event.name;
    final mime = await _controller.getFileMIME(event);
    final bytes = await _controller.getFileSize(event);
    final url = await _controller.createFileUrl(event);
    XFile f = XFile(url, mimeType: mime, length: bytes, name: name);
    setState(() {
      _size = bytes;
      _image = f;
    });
  }

  _pickImage() async {
    XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      int size = await image.length();
      setState(() {
        _size = size;
        _image = image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool warning = _image != null && _size != null && _size! > 102400;
    return SingleChildScrollView(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 1000) {
            return Column(
              children: [_buildPicture(constraints.maxWidth / 3), _buildForm()],
            );
          } else {
            return Column(
              children: [
                _buildPicture(constraints.maxWidth / 6),
                warning
                    ? Text(
                        'Image selected is too big!',
                        style: TextStyle(
                          color: Colors.red,
                        ),
                      )
                    : Container(),
                _buildForm()
              ],
            );
          }
        },
      ),
    );
  }
}
