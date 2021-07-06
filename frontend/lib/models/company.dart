import 'package:frontend/models/contact.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/package.dart';
import 'package:frontend/models/thread.dart';

class Company {
  final String id;
  final String name;
  final String description;
  final CompanyImages companyImages;
  final String site;
  final List<CompanyRep> employees;
  final CompanyBillingInfo billingInfo;
  final List<CompanyParticipation> participations;

  Company({
    this.id,
    this.name,
    this.description,
    this.companyImages,
    this.site,
    this.employees,
    this.billingInfo,
    this.participations,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    var employees = json['employers'] as List;
    var participations = json['participations'] as List;
    return Company(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      companyImages: CompanyImages.fromJson(json['companyImages']),
      site: json['site'],
      employees: employees.map((e) => CompanyRep.fromJson(e)).toList(),
      billingInfo: CompanyBillingInfo.fromJson(json['billingInfo']),
      participations:
          participations.map((e) => CompanyParticipation.fromJson(e)).toList(),
    );
  }
}

class CompanyImages {
  final String internal;
  final String public;

  CompanyImages({
    this.internal,
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
  final String id;
  final String name;
  final Contact contact;

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
  final String name;
  final String address;
  final String tin;

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
}

class CompanyParticipation {
  final int event;
  final Member member;
  final String status;
  final List<Thread> communications;
  final Package package;
  final DateTime confirmed;
  final bool partner;
  final String notes;

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
    var threads = json['communications'] as List;
    return CompanyParticipation(
      event: json['event'],
      member: Member.fromJson(json['member']),
      status: json['status'],
      communications: threads.map((e) => Thread.fromJson(e)).toList(),
      package: Package.fromJson(json['package']),
      confirmed: DateTime(json['confirmed']),
      partner: json['partner'],
      notes: json['notes'],
    );
  }
}
