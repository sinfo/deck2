import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/services/memberService.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class EditMemberForm extends StatefulWidget {
  final Member member;
  EditMemberForm({Key? key, required this.member}) : super(key: key);

  @override
  _EditMemberFormState createState() => _EditMemberFormState();
}

class _EditMemberFormState extends State<EditMemberForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _istIdController;
  final _memberService = MemberService();
  final _imagePicker = ImagePicker();
  XFile? _image;
  int? _size;
  String? _prevImage;
  late DropzoneViewController _controller;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member.name);
    _istIdController = TextEditingController(text: widget.member.id);
    _prevImage = widget.member.image;
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      var name = _nameController.text;
      var istId = _istIdController.text;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading')),
      );

      print('id = ${widget.member.id}');

      Member? m =
          await _memberService.updateMember(widget.member.id, name, istId);
      if (m != null && _image != null) {
        //FIXME: update image
        // m = kIsWeb
        //     ? await _memberService.updateInternalImageWeb(
        //         id: m.id, image: _image!)
        //     : await _memberService.updateInternalImage(
        //         id: m.id, image: File(_image!.path));
      }
      if (m != null) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

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
                  return 'Please enter a name';
                }
                return null;
              },
              decoration: const InputDecoration(
                icon: const Icon(Icons.person),
                labelText: "Name *",
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _istIdController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter ist id';
                } else {
                  return null;
                }
              },
              decoration: const InputDecoration(
                icon: const Icon(Icons.school),
                labelText: "IstId *",
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
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.secondary)),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: Theme.of(context).colorScheme.secondary,
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
    // bool warning = _image != null && _size != null && _size! > 102400;

    return Scaffold(
        appBar: CustomAppBar(disableEventChange: true,),
        body: LayoutBuilder(builder: (contex, constraints) {
          return Column(children: [
            _buildForm(),
          ]);
        }));

    // return SingleChildScrollView(
    //   child: LayoutBuilder(
    //     builder: (context, constraints) {
    //       if (constraints.maxWidth < 1000) {
    //         return Column(
    //           children: [_buildPicture(constraints.maxWidth / 3), _buildForm()],
    //         );
    //       } else {
    //         return Column(
    //           children: [
    //             _buildPicture(constraints.maxWidth / 6),
    //             warning
    //                 ? Text(
    //                     'Image selected is too big!',
    //                     style: TextStyle(
    //                       color: Colors.red,
    //                     ),
    //                   )
    //                 : Container(),
    //             _buildForm()
    //           ],
    //         );
    //       }
    //     },
    //   ),
    // );
  }
}
