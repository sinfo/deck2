import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';
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
  _EditContactState createState() => _EditContactState();
}

class _EditContactState extends State<EditContact> {
  ContactService contactService = new ContactService();
  var newListContactMail = List<ContactMail>.empty(growable: true);
  var newListContactPhone = List<ContactPhone>.empty(growable: true);

  var newMails = List<String?>.empty(growable: true);
  var newMailsPersonal = List<bool?>.empty(growable: true);
  var newMailsValid = List<bool?>.empty(growable: true);
  var newPhones = List<String?>.empty(growable: true);
  var newPhonesValid = List<bool?>.empty(growable: true);
  String? _facebook;
  String? _twitter;
  String? _github;
  String? _skype;
  String? _linkedin;

  //Copy the contact

  @override
  Widget build(BuildContext context) {
    // Create the new list of contact mails
    for (int i = 0; i < widget.contact.mails!.length; i++) {
      newMails.add(widget.contact.mails![i].mail);
      newMailsValid.add(widget.contact.mails![i].valid);
      newMailsPersonal.add(widget.contact.mails![i].personal);
    }

    // Copy the phones
    for (int i = 0; i < widget.contact.phones!.length; i++) {
      newPhones.add(widget.contact.phones![i].phone);
      newPhonesValid.add(widget.contact.phones![i].valid);
    }

    // Copy the social networks
    _facebook = (widget.contact.socials!.facebook != null)
        ? widget.contact.socials!.facebook!
        : '';
    _twitter = (widget.contact.socials!.twitter != null)
        ? widget.contact.socials!.twitter!
        : '';
    _skype = (widget.contact.socials!.skype != null)
        ? widget.contact.socials!.skype!
        : '';
    _linkedin = (widget.contact.socials!.linkedin != null)
        ? widget.contact.socials!.linkedin!
        : '';
    _github = (widget.contact.socials!.github != null)
        ? widget.contact.socials!.github!
        : '';

    return Scaffold(
      appBar: CustomAppBar(),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 32),
        physics: BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 24),

          //Mails Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Mails",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(onPressed: () {}, child: Text('Add new'))
            ],
          ),
          for (int i = 0; i < widget.contact.mails!.length; i++)
            Column(
              children: [
                TextFormField(
                    initialValue: newMails[i],
                    onChanged: (mail) {
                      newMails[i] = mail;
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),),
                    
                //FIXME: não sei ainda porquê, mas isto não muda o estado TT_TT
                SwitchListTile(
                    value: newMailsValid[i]!,
                    title: Text("Valid"),
                    onChanged: (bool newValue) {
                      setState(
                        () {
                          newMailsValid[i] = newValue;
                        },
                      );
                    }),
                SwitchListTile(
                    value: newMailsPersonal[i]!,
                    title: Text("Personal"),
                    onChanged: (newValue) {
                      setState(() {
                        newMailsPersonal[i] = newValue;
                      });
                    })
              ],
            ),
          const SizedBox(height: 24),

          // Phones Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Phones",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(onPressed: () {}, child: Text('Add new'))
            ],
          ),
          for (int i = 0; i < widget.contact.phones!.length; i++)
            Column(
              children: [
                TextFormField(
                    initialValue: newPhones[i],
                    onChanged: (phone) {
                      newPhones[i] = phone;
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),),
                SwitchListTile(
                    value: newPhonesValid[i]!,
                    title: Text("Valid"),
                    onChanged: (newValue) {
                      setState(() {
                        newPhonesValid[i] = newValue;
                      });
                      // TODO: mudar o backend
                    })
              ],
            ),
          const SizedBox(height: 24),

          // Socials Section
          Text("Socials",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          // Facebook
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
                      _facebook = facebook;
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
                  _github = github;
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
                  _twitter = twitter;
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
                  _skype = skype;
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
                  _linkedin = linkedin;
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )),
            ],
          ),

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MemberScreen(
                            member: widget.member, role: "whatever")),
                  );
                },
                child: Text('Cancel')),
              ElevatedButton(
                  onPressed: () async {
                    //FIXME: length pode mudar com o delete
                    for (int i = 0; i < widget.contact.mails!.length; i++) {
                      newListContactMail.add(new ContactMail(
                          mail: newMails[i],
                          valid: newMailsValid[i],
                          personal: newMailsPersonal[i]));
                    }

                    //FIXME: length pode mudar com o delete
                    for (int i = 0; i < widget.contact.phones!.length; i++) {
                      newListContactPhone.add(new ContactPhone(
                          phone: newPhones[i], valid: newPhonesValid[i]));
                    }

                    await contactService.updateContact(new Contact(
                        id: widget.contact.id,
                        mails: newListContactMail,
                        phones: newListContactPhone,
                        socials: new ContactSocials(
                            facebook: _facebook,
                            twitter: _twitter,
                            github: _github,
                            skype: _skype,
                            linkedin: _linkedin)));

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => MemberScreen(
                              member: widget.member, role: "whatever")),
                    );
                  },
                  child: Text('Save'))
              ],
            ),

          const SizedBox(height: 24,)
        ],
      ),
    );
  }
}

