import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/blurryDialog.dart';
import 'package:frontend/models/contact.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/my_flutter_app_icons.dart';
import 'package:frontend/routes/member/MemberScreen.dart';
import 'package:frontend/services/contactService.dart';

class EditContact extends StatefulWidget {
  Contact contact;
  Member member;

  EditContact({Key? key, required Contact this.contact, required this.member})
      : super(key: key);

  @override
  _MyFormState createState() => _MyFormState();
}

class _MyFormState extends State<EditContact> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _mailController;

  ContactService contactService = new ContactService();
  var newListContactMail = List<ContactMail>.empty(growable: true);
  var newListContactPhone = List<ContactPhone>.empty(growable: true);

  static var mailsList = List<String?>.empty(growable: true);
  static var mailsPersonalList = List<bool?>.empty(growable: true);
  static var mailsValidList = List<bool?>.empty(growable: true);
  static var phonesList = List<String?>.empty(growable: true);
  static var phonesValidList = List<bool?>.empty(growable: true);
  static String? facebook;
  static String? github;
  static String? twitter;
  static String? linkedin;
  static String? skype;

  @override
  void initState() {
    super.initState();

    // Copy mails
    for (int i = 0; i < widget.contact.mails!.length; i++) {
      mailsList.add(widget.contact.mails![i].mail);
      mailsPersonalList.add(widget.contact.mails![i].personal);
      mailsValidList.add(widget.contact.mails![i].valid);
    }

    // Copy phones
    for (int i = 0; i < widget.contact.phones!.length; i++) {
      phonesList.add(widget.contact.phones![i].phone);
      phonesValidList.add(widget.contact.phones![i].valid);
    }

    facebook = widget.contact.socials!.facebook;
    github = widget.contact.socials!.github;
    twitter = widget.contact.socials!.twitter;
    skype = widget.contact.socials!.skype;
    linkedin = widget.contact.socials!.linkedin;

    _mailController = TextEditingController();
  }

  @override
  void dispose() {
    _mailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        disableEventChange: true,
      ),
      body: ListView(
          padding: EdgeInsets.symmetric(horizontal: 32),
          physics: BouncingScrollPhysics(),
          children: [
            Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 24,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Mails",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        TextButton(
                            // Add new form field
                            onPressed: () {
                              mailsList.add('');
                              mailsValidList.add(false);
                              mailsPersonalList.add(false);
                              setState(() {});
                            },
                            child: Text('Add new'))
                      ],
                    ),
                    ..._getMails(),
                    SizedBox(
                      height: 24,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Phones",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        TextButton(
                            // Add new form field
                            onPressed: () {
                              phonesList.add('');
                              phonesValidList.add(false);
                              setState(() {});
                            },
                            child: Text('Add new'))
                      ],
                    ),
                    ..._getPhones(),
                    SizedBox(
                      height: 24,
                    ),

                    // Socials Section
                    Text("Socials",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    GetSocials(),

                    SizedBox(height: 40),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 50),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: () {
                            //Do not remove this, otherwise it will duplicate
                            mailsList.clear();
                            mailsValidList.clear();
                            mailsPersonalList.clear();
                            phonesList.clear();
                            phonesValidList.clear();

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      MemberScreen(member: widget.member)),
                            );
                          },
                          child: Text("CANCEL",
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).accentColor)),
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
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                // If the form is valid, display a snackbar. In the real world,
                                // you'd often call a server or save the information in a database.
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Updated Contacts')),
                                );

                                for (int i = 0; i < mailsList.length; i++) {
                                  newListContactMail.add(new ContactMail(
                                      mail: mailsList[i],
                                      valid: mailsValidList[i],
                                      personal: mailsPersonalList[i]));
                                }

                                for (int i = 0; i < phonesList.length; i++) {
                                  newListContactPhone.add(new ContactPhone(
                                      phone: phonesList[i],
                                      valid: phonesValidList[i]));
                                }

                                await contactService.updateContact(new Contact(
                                    id: widget.contact.id,
                                    mails: newListContactMail,
                                    phones: newListContactPhone,
                                    socials: new ContactSocials(
                                        facebook: facebook,
                                        twitter: twitter,
                                        github: github,
                                        skype: skype,
                                        linkedin: linkedin)));

                                //Do not remove this, otherwise it will duplicate
                                mailsList.clear();
                                mailsValidList.clear();
                                mailsPersonalList.clear();
                                phonesList.clear();
                                phonesValidList.clear();

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          MemberScreen(member: widget.member)),
                                );
                              }
                            },
                            child: const Text('SUBMIT'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ]),
    );
  }

  Widget GetSocials() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Icon(MyFlutterApp.facebook_circled,
                  size: 35, color: Color.fromRGBO(24, 119, 242, 1)),
            ),
            Flexible(
                child: TextFormField(
              initialValue: (widget.contact.socials!.facebook != null)
                  ? widget.contact.socials!.facebook!
                  : '',
              onChanged: (facebook) {
                _MyFormState.facebook = facebook;
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )),
          ],
        ),
        const SizedBox(height: 8),

        // Github
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Icon(
                MyFlutterApp.github_circled,
                size: 35,
                color: Color.fromRGBO(51, 51, 51, 1),
              ),
            ),
            Flexible(
                child: TextFormField(
              initialValue: (widget.contact.socials!.github != null)
                  ? widget.contact.socials!.github!
                  : '',
              onChanged: (github) {
                _MyFormState.github = github;
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )),
          ],
        ),
        const SizedBox(height: 8),
        // Twitter
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Icon(MyFlutterApp.twitter_circled,
                  size: 35, color: Color.fromRGBO(29, 161, 242, 1)),
            ),
            Flexible(
                child: TextFormField(
              initialValue: (widget.contact.socials!.twitter != null)
                  ? widget.contact.socials!.twitter!
                  : '',
              onChanged: (twitter) {
                _MyFormState.twitter = twitter;
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )),
          ],
        ),

        const SizedBox(height: 8),

        // Skype
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Icon(
                MyFlutterApp.skype_circled,
                size: 35,
                color: Color.fromRGBO(0, 175, 240, 1),
              ),
            ),
            Flexible(
                child: TextFormField(
              initialValue: (widget.contact.socials!.skype != null)
                  ? widget.contact.socials!.skype!
                  : '',
              onChanged: (skype) {
                _MyFormState.skype = skype;
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )),
          ],
        ),

        const SizedBox(height: 8),

        // Linkedin
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(
                MyFlutterApp.linkedin_circled,
                size: 35,
                color: Color.fromRGBO(10, 102, 194, 1),
              ),
            ),
            Flexible(
                child: TextFormField(
              initialValue: (widget.contact.socials!.linkedin != null)
                  ? widget.contact.socials!.linkedin!
                  : '',
              onChanged: (linkedin) {
                _MyFormState.linkedin = linkedin;
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )),
          ],
        ),
      ],
    );
  }

  List<Widget> _getMails() {
    List<Widget> mailsTextFieldsList = [];

    for (int i = 0; i < mailsList.length; i++) {
      mailsTextFieldsList.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: MailsTextFields(i)),
            SizedBox(
              width: 16,
            ),
            // we need add button at last friends row only
            _removeButton(i, 'mail'),
          ],
        ),
      ));
    }
    return mailsTextFieldsList;
  }

  List<Widget> _getPhones() {
    List<Widget> phonesTextFieldsList = [];

    for (int i = 0; i < phonesList.length; i++) {
      phonesTextFieldsList.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: PhonesTextFields(i)),
            SizedBox(
              width: 16,
            ),
            // we need add button at last friends row only
            _removeButton(i, 'phone'),
          ],
        ),
      ));
    }
    return phonesTextFieldsList;
  }

  /// add / remove button
  Widget _removeButton(int index, String tag) {
    return InkWell(
      onTap: () {
        BlurryDialog d = BlurryDialog(
            'Warning', 'Are you sure you want to delete this ${tag}?', () {
          if (tag == 'mail') {
            mailsList.removeAt(index);
            mailsValidList.removeAt(index);
            mailsPersonalList.removeAt(index);
          } else if (tag == 'phone') {
            phonesList.removeAt(index);
            phonesValidList.removeAt(index);
          }

          setState(() {});
        });

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return d;
          },
        );
      },
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          Icons.remove,
          color: Colors.white,
        ),
      ),
    );
  }
}

class MailsTextFields extends StatefulWidget {
  final int index;
  MailsTextFields(this.index);
  @override
  _MailsTextFieldsState createState() => _MailsTextFieldsState();
}

class _MailsTextFieldsState extends State<MailsTextFields> {
  late TextEditingController _mailController;
  @override
  void initState() {
    super.initState();
    _mailController = TextEditingController();
  }

  @override
  void dispose() {
    _mailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _mailController.text = _MyFormState.mailsList[widget.index] ?? '';
    });
    return Column(
      children: [
        TextFormField(
          controller: _mailController,
          // save text field data in friends list at index
          // whenever text field value changes
          onChanged: (v) => _MyFormState.mailsList[widget.index] = v,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            //TODO: esta validação pode estar melhor
            if (value == null || value.isEmpty || !value.contains('@')) {
              return 'Please enter a valid mail';
            }
            return null;
          },
        ),
        SwitchListTile(
          value: _MyFormState.mailsValidList[widget.index]!,
          title: Text("Valid"),
          onChanged: (v) {
            setState(() {
              _MyFormState.mailsValidList[widget.index] = v;
            });
          },
        ),
        SwitchListTile(
            value: _MyFormState.mailsPersonalList[widget.index]!,
            title: Text("Personal"),
            onChanged: (v) {
              setState(() {
                _MyFormState.mailsPersonalList[widget.index] = v;
              });
            })
      ],
    );
  }
}

class PhonesTextFields extends StatefulWidget {
  final int index;
  PhonesTextFields(this.index);
  @override
  _PhonesTextFieldsState createState() => _PhonesTextFieldsState();
}

class _PhonesTextFieldsState extends State<PhonesTextFields> {
  late TextEditingController _phoneController;
  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _phoneController.text = _MyFormState.phonesList[widget.index] ?? '';
    });
    return Column(
      children: [
        TextFormField(
          controller: _phoneController,
          // save text field data in friends list at index
          // whenever text field value changes
          onChanged: (v) => _MyFormState.phonesList[widget.index] = v,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a phone';
            }
            return null;
          },
        ),
        SwitchListTile(
          value: _MyFormState.phonesValidList[widget.index]!,
          title: Text("Valid"),
          onChanged: (v) {
            setState(() {
              _MyFormState.phonesValidList[widget.index] = v;
            });
          },
        ),
      ],
    );
  }
}
