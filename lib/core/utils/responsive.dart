import 'package:flutter/material.dart';

class Breakpoints {
  static const mobile = 600.0;
}

bool isMobile(BuildContext context) {
  return MediaQuery.of(context).size.width < Breakpoints.mobile;
}
