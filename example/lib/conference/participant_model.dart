import 'package:flutter/material.dart';

class ParticipantModel {
  final bool isRemote;
  final Widget widget;
  final String id;

  ParticipantModel({
    this.isRemote = true,
    @required this.widget,
    @required this.id,
  }) : assert(widget != null);
}
