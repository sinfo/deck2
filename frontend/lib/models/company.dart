import 'package:frontend/models/contact.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/package.dart';
import 'package:frontend/models/thread.dart';

class PublicCompany {
  final String id;
  final String img;
  final String name;
  final List<CompanyParticipation>? participations;
  final String site;

  PublicCompany(
      {required this.id,
      required this.img,
      required this.name,
      this.participations,
      required this.site});

  factory PublicCompany.fromJson(Map<String, dynamic> json) {
    var participations = json['participations'] as List;
    return PublicCompany(
        id: json['id'],
        img: json['img'],
        name: json['name'],
        participations: participations
            .map((e) => CompanyParticipation.fromJson(e))
            .toList(),
        site: json['site']);
  }
}

class CompanyLight {
  final String id;
  final String name;
  final CompanyImages companyImages;

  CompanyLight({
    required this.id,
    required this.name,
    required this.companyImages,
  });

  factory CompanyLight.fromJson(Map<String, dynamic> json) {
    return CompanyLight(
      id: json['id'],
      name: json['name'],
      companyImages: CompanyImages.fromJson(json['imgs']),
    );
  }
}

class Company {
  final String? id;
  final String name;
  final String? description;
  final CompanyImages companyImages;
  final String? site;
  final List<String>? employers;
  final CompanyBillingInfo? billingInfo;
  final List<CompanyParticipation>? participations;

  Company({
    this.id,
    required this.name,
    this.description,
    required this.companyImages,
    this.site,
    this.employers,
    this.billingInfo,
    this.participations,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    var jsonParticipations = json['participations'] as List;
    var employers = json['employers'] as List<String>?;
    var participations = jsonParticipations
        .map((e) => CompanyParticipation.fromJson(e))
        .toList();
    return Company(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      companyImages: CompanyImages.fromJson(json['imgs']),
      site: json['site'],
      employers: employers,
      billingInfo: CompanyBillingInfo.fromJson(json['billingInfo']),
      participations: participations,
    );
  }
}

class CompanyImages {
  final String internal;
  final String? public;

  CompanyImages({
    required this.internal,
    this.public,
  });

  factory CompanyImages.fromJson(Map<String, dynamic> json) {
    return CompanyImages(
      internal: json['internal'],
      public: json['public'],
    );
  }
}

class CompanyRep {
  final String? id;
  final String? name;
  final Contact? contact;

  CompanyRep({
    this.id,
    this.name,
    this.contact,
  });

  factory CompanyRep.fromJson(Map<String, dynamic> json) {
    return CompanyRep(
      id: json['id'],
      name: json['name'],
      contact: Contact.fromJson(json['contact']),
    );
  }
}

class CompanyBillingInfo {
  final String? name;
  final String? address;
  final String? tin;

  CompanyBillingInfo({
    this.name,
    this.address,
    this.tin,
  });

  factory CompanyBillingInfo.fromJson(Map<String, dynamic> json) {
    return CompanyBillingInfo(
      name: json['name'],
      address: json['address'],
      tin: json['tin'],
    );
  }

  Map<String, dynamic> toJson() =>
      {'name': name, 'address': address, 'tin': tin};
}

class CompanyParticipation {
  final int? event;
  final String? member;
  final String? status;
  final List<String>? communications;
  final String? package;
  final DateTime? confirmed;
  final bool? partner;
  final String? notes;

  CompanyParticipation({
    this.event,
    this.member,
    this.status,
    this.communications,
    this.package,
    this.confirmed,
    this.partner,
    this.notes,
  });

  factory CompanyParticipation.fromJson(Map<String, dynamic> json) {
    CompanyParticipation result = CompanyParticipation(
      event: json['event'],
      member: json['member'],
      status: json['status'],
      communications: List.from(json['communications']),
      package: json['package'],
      confirmed: DateTime.parse(json['confirmed']),
      partner: json['partner'],
      notes: json['notes'],
    );
    print(result);
    return result;
  }
}
