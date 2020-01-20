import 'package:flutter/material.dart';

class Participant {
  final bool isRemote;
  final Widget widget;
  final String id;

  Participant({
    this.isRemote = true,
    @required this.widget,
    @required this.id,
  }) : assert(widget != null);
}
