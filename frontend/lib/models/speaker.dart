import 'package:frontend/main.dart';
import 'package:frontend/models/participation.dart';
import 'package:collection/collection.dart';

class Images {
  final String? company;
  final String? internal;
  final String? speaker;

  Images({this.company, this.internal, this.speaker});

  factory Images.fromJson(Map<String, dynamic> json) {
    return Images(
        company: json['company'],
        internal: json['internal'],
        speaker: json['speaker']);
  }

  Map<String, dynamic> toJson() =>
      {'company': company, 'internal': internal, 'speaker': speaker};
}

class Speaker {
  final String id;
  final String name;
  final String? title;
  final String? contact; //TODO: lazy load
  final String? bio;
  final String? notes;
  final Images? imgs;
  final List<SpeakerParticipation>? participations;
  final int? numParticipations;
  final int? lastParticipation;
  final ParticipationStatus? participationStatus;

  Speaker(
      {required this.id,
      required this.name,
      this.title,
      this.contact,
      this.bio,
      this.notes,
      this.imgs,
      this.participations,
      this.numParticipations,
      this.lastParticipation,
      this.participationStatus});

  factory Speaker.fromJson(Map<String, dynamic> json) {
    var participationsList = json['participations'] as List;
    return Speaker(
      id: json['id'],
      name: json['name'],
      title: json['title'],
      contact: json['contact'],
      bio: json['bio'],
      notes: json['notes'],
      imgs: Images.fromJson(json['imgs']),
      participations: participationsList
          .map((p) => SpeakerParticipation.fromJson(p))
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'title': title,
        'contact': contact,
        'bio': bio,
        'notes': notes,
        'imgs': imgs?.toJson(),
        'participations':
            participations?.map((participation) => participation.toJson())
      };

  SpeakerParticipation? getParticipation(int event) {
    return this
        .participations!
        .firstWhereOrNull((element) => element.event == event);
  }

  SpeakerParticipation getLatestParticipation() {
    return this.participations!.firstWhereOrNull(
        (element) => element.event == this.lastParticipation)!;
  }

  bool operator ==(o) => o is Speaker && id == o.id;
  int get hashCode => id.hashCode;
}

class PublicImages {
  final String? company;
  final String? speaker;

  PublicImages({this.company, this.speaker});

  factory PublicImages.fromJson(Map<String, dynamic> json) {
    return PublicImages(company: json['company'], speaker: json['speaker']);
  }

  Map<String, dynamic> toJson() => {'company': company, 'speaker': speaker};
}

class PublicSpeaker {
  final String? id;
  final String? name;
  final String? title;
  final Images? imgs;

  PublicSpeaker({this.id, this.name, this.title, this.imgs});

  factory PublicSpeaker.fromJson(Map<String, dynamic> json) {
    return PublicSpeaker(
        id: json['id'],
        name: json['name'],
        title: json['title'],
        imgs: Images.fromJson(json['imgs']));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'title': title,
        'imgs': imgs?.toJson(),
      };
}

class SpeakerLight {
  final String id;
  final String name;
  final Images speakerImages;
  final int? numParticipations;
  final int? lastParticipation;
  final ParticipationStatus participationStatus;

  SpeakerLight(
      {required this.id,
      required this.name,
      required this.speakerImages,
      this.numParticipations,
      this.lastParticipation,
      required this.participationStatus});

  factory SpeakerLight.fromJson(Map<String, dynamic> json) {
    var participations = json['participations'] as List;
    return SpeakerLight(
        id: json['id'],
        name: json['name'],
        speakerImages: Images.fromJson(json['imgs']),
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