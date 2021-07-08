import 'dart:convert';

class Contact {
  final String? id;
  final List<ContactPhone>? phones;
  final ContactSocials? socials;
  final List<ContactMail>? mails;

  Contact({this.id, this.phones, this.socials, this.mails});

  factory Contact.fromJson(Map<String, dynamic> json) {
    var phones = json['phones'] as List;
    var mails = json['mails'] as List;
    return Contact(
      id: json['id'],
      phones: phones.map((e) => ContactPhone.fromJson(e)).toList(),
      socials: ContactSocials.fromJson(json['socials']),
      mails: mails.map((e) => ContactMail.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phones': jsonEncode(phones),
        'socials': socials?.toJson(),
        'mails': jsonEncode(mails),
      };
}

class ContactPhone {
  final String? phone;
  final bool? valid;

  ContactPhone({
    this.phone,
    this.valid,
  });

  factory ContactPhone.fromJson(Map<String, dynamic> json) {
    return ContactPhone(
      phone: json['phone'],
      valid: json['valid'],
    );
  }

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'valid': valid,
      };
}

class ContactSocials {
  final String? facebook;
  final String? skype;
  final String? github;
  final String? twitter;
  final String? linkedin;

  ContactSocials({
    this.facebook,
    this.skype,
    this.github,
    this.twitter,
    this.linkedin,
  });

  factory ContactSocials.fromJson(Map<String, dynamic> json) {
    return ContactSocials(
      facebook: json['facebook'],
      skype: json['skype'],
      github: json['github'],
      twitter: json['twitter'],
      linkedin: json['linkedin'],
    );
  }

  Map<String, dynamic> toJson() => {
        'facebook': facebook,
        'skype': skype,
        'github': github,
        'twitter': twitter,
        'linkedin': linkedin,
      };
}

class ContactMail {
  final String? mail;
  final bool? valid;
  final bool? personal;

  ContactMail({
    this.mail,
    this.valid,
    this.personal,
  });

  factory ContactMail.fromJson(Map<String, dynamic> json) {
    return ContactMail(
      mail: json['mail'],
      valid: json['valid'],
      personal: json['personal'],
    );
  }

  Map<String, dynamic> toJson() => {
        'mail': mail,
        'valid': valid,
        'personal': personal,
      };
}
