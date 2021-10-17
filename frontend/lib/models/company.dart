import 'package:frontend/main.dart';
import 'package:frontend/models/contact.dart';
import 'package:frontend/models/participation.dart';
import 'package:frontend/services/contactService.dart';
import 'package:collection/collection.dart';

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
  final int? numParticipations;
  final int? lastParticipation;
  final ParticipationStatus participationStatus;

  CompanyLight(
      {required this.id,
      required this.name,
      required this.companyImages,
      this.numParticipations,
      this.lastParticipation,
      required this.participationStatus});

  factory CompanyLight.fromJson(Map<String, dynamic> json) {
    var participations = json['participations'] as List;
    return CompanyLight(
        id: json['id'],
        name: json['name'],
        companyImages: CompanyImages.fromJson(json['imgs']),
        numParticipations: participations.length,
        lastParticipation: participations.length > 0
            ? participations[participations.length - 1]['event']
            : null,
        participationStatus: participations.length > 0 &&
                participations[participations.length - 1]['event'] ==
                    App.localStorage.getInt("event")
            ? Participation.convert(
                participations[participations.length - 1]['status'])
            : ParticipationStatus.NO_STATUS);
  }
}

class Company {
  final String id;
  final String name;
  final String? description;
  final CompanyImages companyImages;
  final String? site;
  List<CompanyRep>? employees;
  CompanyBillingInfo? billingInfo;
  List<CompanyParticipation>? participations;
  final int? numParticipations;
  final int? lastParticipation;
  final ParticipationStatus? participationStatus;

  Company({
    required this.id,
    required this.name,
    this.description,
    required this.companyImages,
    this.site,
    this.employees,
    this.billingInfo,
    this.participations,
    this.numParticipations,
    this.lastParticipation,
    this.participationStatus,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    // var employees = json['employers'] as List;
    var participationsList = json['participations'] as List;
    return Company(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      companyImages: CompanyImages.fromJson(json['imgs']),
      site: json['site'],
      // employees: employees.map((e) => CompanyRep.fromJson(e)).toList(),
      billingInfo: CompanyBillingInfo.fromJson(json['billingInfo']),
      participations: participationsList
          .map((e) => CompanyParticipation.fromJson(e))
          .toList(),
      numParticipations: participationsList.length,
      lastParticipation: participationsList.length > 0
          ? participationsList[participationsList.length - 1]['event']
          : null,
      participationStatus: participationsList.length > 0 &&
              participationsList[participationsList.length - 1]['event'] ==
                  App.localStorage.getInt("event")
          ? Participation.convert(
              participationsList[participationsList.length - 1]['status'])
          : ParticipationStatus.NO_STATUS,
    );
  }

  CompanyParticipation? getParticipation(int event) {
    return this
        .participations!
        .firstWhereOrNull((element) => element.event == event);
  }

  CompanyParticipation getLatestParticipation() {
    return this.participations!.firstWhereOrNull(
        (element) => element.event == this.lastParticipation)!;
  }

  bool operator ==(o) => o is Company && id == o.id;
  int get hashCode => id.hashCode;
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
  final String id;
  final String name;
  final String contactID;
  Contact? _contact;
  ContactService _contactService = ContactService();

  CompanyRep({
    required this.id,
    required this.name,
    required this.contactID,
  });

  factory CompanyRep.fromJson(Map<String, dynamic> json) {
    return CompanyRep(
      id: json['id'],
      name: json['name'],
      contactID: json['contact'],
    );
  }

  Future<Contact?> get contact async {
    if (_contact != null) return _contact;
    _contact = await _contactService.getContact(contactID);
    return _contact;
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
