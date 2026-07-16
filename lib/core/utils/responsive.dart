import 'package:flutter/material.dart';

class Breakpoints {
  static const mobile = 600.0;

  /// Above [mobile] but below this, the page still uses "desktop" type
  /// sizing/padding, but paired side-by-side cards don't have enough room
  /// to sit next to each other without cramming — so layouts with two
  /// cards in a row should stack to one column here instead of waiting
  /// for [mobile].
  static const compact = 900.0;
}

bool isMobile(BuildContext context) {
  return MediaQuery.of(context).size.width < Breakpoints.mobile;
}

/// True below [Breakpoints.compact] — use this (instead of [isMobile]) to
/// decide whether a row of two-or-more side-by-side cards should stack,
/// since those need more horizontal room than the mobile/desktop type
/// breakpoint alone accounts for.
bool isCompact(BuildContext context) {
  return MediaQuery.of(context).size.width < Breakpoints.compact;
}
