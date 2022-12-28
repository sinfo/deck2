import 'dart:convert';

import 'package:intl/intl.dart';

class BillingStatus {
  final bool proForma;
  final bool invoice;
  final bool receipt;
  final bool paid;

  BillingStatus(
      {required this.proForma,
      required this.invoice,
      required this.receipt,
      required this.paid});

  factory BillingStatus.fromJson(Map<String, dynamic> json) {
    return BillingStatus(
      proForma: json['proForma'],
      invoice: json['invoice'],
      receipt: json['receipt'],
      paid: json['paid'],
    );
  }

  Map<String, dynamic> toJson() => {
        'proForma': proForma,
        'invoice': invoice,
        'receipt': receipt,
        'paid': paid,
      };

  @override
  String toString() {
    return json.encode(this.toJson());
  }
}

class Billing {
  final String id;
  final BillingStatus status;
  final int event;
  final String? company;
  final int value;
  final String invoiceNumber;
  final DateTime emission;
  final String notes;
  final bool visible;

  Billing(
      {required this.id,
      required this.status,
      required this.event,
      this.company,
      required this.value,
      required this.invoiceNumber,
      required this.emission,
      required this.notes,
      required this.visible});

  factory Billing.fromJson(Map<String, dynamic> json) {
    return Billing(
      id: json['id'],
      status: BillingStatus.fromJson(json['status']),
      event: json['event'],
      company: json['company'],
      value: json['value'],
      invoiceNumber: json['invoiceNumber'],
      emission: DateTime.parse(json['emission']),
      notes: json['notes'],
      visible: json['visible'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status,
        'event': event,
        'company': company,
        'value': value,
        'invoiceNumber': invoiceNumber,
        'emission': emission,
        'notes': notes,
        'visible': visible,
      };

  @override
  String toString() {
    String repr = "";
    Map<String, dynamic> bill = this.toJson();
    bill.forEach((key, value) {
      repr += key + ' ';
      if (value != DateTime) {
        repr += value.toString();
      } else {
        repr += DateFormat('yyyy-MM-dd HH:mm').format(value);
      }
      repr += '\n';
    });
    return repr;
  }
}
