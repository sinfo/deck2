import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/participation.dart';

final Map<ParticipationStatus, String> STATUSSTRING = {
  ParticipationStatus.ACCEPTED: 'Accepted',
  ParticipationStatus.ANNOUNCED: 'Announced',
  ParticipationStatus.CONTACTED: 'Contacted',
  ParticipationStatus.GIVEN_UP: 'Given Up',
  ParticipationStatus.IN_CONVERSATIONS: 'In Convers.',
  ParticipationStatus.ON_HOLD: 'On Hold',
  ParticipationStatus.REJECTED: 'Rejected',
  ParticipationStatus.SELECTED: 'Selected',
  ParticipationStatus.SUGGESTED: 'Suggested',
  ParticipationStatus.NO_STATUS: '',
};

final Map<ParticipationStatus, String> STATUSFILTER = {
  ParticipationStatus.NO_STATUS: 'All',
  ParticipationStatus.ACCEPTED: 'Accepted',
  ParticipationStatus.ANNOUNCED: 'Announced',
  ParticipationStatus.CONTACTED: 'Contacted',
  ParticipationStatus.GIVEN_UP: 'Given Up',
  ParticipationStatus.IN_CONVERSATIONS: 'In Convers.',
  ParticipationStatus.ON_HOLD: 'On Hold',
  ParticipationStatus.REJECTED: 'Rejected',
  ParticipationStatus.SELECTED: 'Selected',
  ParticipationStatus.SUGGESTED: 'Suggested',
};

final Map<ParticipationStatus, Color> STATUSCOLOR = {
  ParticipationStatus.ACCEPTED: Colors.lightGreen,
  ParticipationStatus.ANNOUNCED: Colors.green.shade700,
  ParticipationStatus.CONTACTED: Colors.yellow,
  ParticipationStatus.GIVEN_UP: Colors.black,
  ParticipationStatus.IN_CONVERSATIONS: Colors.lightBlue,
  ParticipationStatus.ON_HOLD: Colors.blueGrey,
  ParticipationStatus.REJECTED: Colors.red,
  ParticipationStatus.SELECTED: Colors.deepPurple,
  ParticipationStatus.SUGGESTED: Colors.amber,
  ParticipationStatus.NO_STATUS: Colors.indigo,
};

final Map<ParticipationStatus, int> STATUSORDER = {
  ParticipationStatus.ANNOUNCED: 0,
  ParticipationStatus.ACCEPTED: 1,
  ParticipationStatus.IN_CONVERSATIONS: 2,
  ParticipationStatus.ON_HOLD: 3,
  ParticipationStatus.CONTACTED: 4,
  ParticipationStatus.SELECTED: 5,
  ParticipationStatus.SUGGESTED: 6,
  ParticipationStatus.REJECTED: 7,
  ParticipationStatus.GIVEN_UP: 8,
  ParticipationStatus.NO_STATUS: 9,
};
