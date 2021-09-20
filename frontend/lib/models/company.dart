import 'package:frontend/main.dart';
import 'package:frontend/models/contact.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/package.dart';
import 'package:frontend/models/participation.dart';
import 'package:frontend/models/thread.dart';
import 'package:frontend/services/contactService.dart';
import 'package:frontend/services/memberService.dart';
import 'package:frontend/services/packageService.dart';
import 'package:frontend/services/threadService.dart';

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

  Company({
    required this.id,
    required this.name,
    this.description,
    required this.companyImages,
    this.site,
    this.employees,
    this.billingInfo,
    this.participations,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    // var employees = json['employers'] as List;
    var participations = json['participations'] as List;
    return Company(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      companyImages: CompanyImages.fromJson(json['imgs']),
      site: json['site'],
      // employees: employees.map((e) => CompanyRep.fromJson(e)).toList(),
      billingInfo: CompanyBillingInfo.fromJson(json['billingInfo']),
      participations:
          participations.map((e) => CompanyParticipation.fromJson(e)).toList(),
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

class CompanyParticipation {
  MemberService _memberService = MemberService();
  PackageService _packageService = PackageService();
  ThreadService _threadService = ThreadService();

  final int event;

  final String memberId;
  Member? _member;

  final ParticipationStatus status;

  final List<String>? communicationsId;
  List<Thread>? _communications;

  final String? packageId;
  Package? _package;

  final DateTime? confirmed;
  final bool? partner;
  final String? notes;

  CompanyParticipation({
    required this.event,
    required this.memberId,
    required this.status,
    this.communicationsId,
    this.packageId,
    this.confirmed,
    this.partner,
    this.notes,
  });

  factory CompanyParticipation.fromJson(Map<String, dynamic> json) {
    return CompanyParticipation(
      event: json['event'],
      memberId: json['member'],
      status: Participation.convert(json['status']),
      communicationsId: List.from(json['communications']),
      packageId: json['package'],
      confirmed: DateTime.parse(json['confirmed']),
      partner: json['partner'],
      notes: json['notes'],
    );
  }

  Future<Member?> get member async {
    if (_member != null) return _member;

    _member = await _memberService.getMember(memberId);
    return _member;
  }

  Future<Package?> get package async {
    if (_package != null) return _package;
    if (packageId == null) return null;

    _package = await _packageService.getPackage(packageId!);
    return _package;
  }

  Future<List<Thread>?> get communications async {
    if (_communications != null) return _communications;
    if (communicationsId == null) return [];

    _communications = [];
    communicationsId!.forEach((element) async {
      Thread? t = await _threadService.getThread(element);
      if (t != null) {
        _communications!.add(t);
      }
    });

    return _communications;
  }
}
