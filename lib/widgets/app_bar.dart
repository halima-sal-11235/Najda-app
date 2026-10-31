import 'package:flutter/material.dart';
import 'package:najda/globals.dart';

PreferredSizeWidget appBarOf(
  String title, {
  List<Widget>? actions,
  Color bg = Colors.white,
  Color fg = textColor,
  bool showBack = true,
}) {
  return AppBar(
    title: Text(title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
    centerTitle: true,
    backgroundColor: bg,
    foregroundColor: fg,
    elevation: 0,
    scrolledUnderElevation: 0,
    actions: actions,
    automaticallyImplyLeading: showBack,
  );
}
