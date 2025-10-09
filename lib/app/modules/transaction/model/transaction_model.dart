import 'package:flutter/material.dart';

class TransactionModel {
  final String type;
  final num amount;
  final String? status;
  final DateTime date;
  final String? podcastTitle;
  final String? postDescription;

  TransactionModel({
    required this.type,
    required this.amount,
    required this.date,
    this.status,
    this.podcastTitle,
    this.postDescription,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      type: json['type'],
      amount: json['amount'],
      status: json['status'],
      date: DateTime.parse(json['date']),
      podcastTitle: json['podcastTitle'],
      postDescription: json['postDescription'],
    );
  }
}
