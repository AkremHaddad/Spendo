/// Money handling for Spendo.
///
/// Amounts are stored and computed as integer millimes (1 TND = 1000 millimes)
/// rather than as `double` dinars. Repeated floating-point addition/subtraction
/// on Firestore balance transactions was drifting (e.g. `126.36999998` instead
/// of `126.37`), and TND actually needs 3 decimal places (millimes), not the 2
/// the UI was showing. Doing arithmetic in integer millimes avoids both:
/// integers don't accumulate binary floating-point rounding error, and the
/// smallest unit (1 millime) already matches the currency's real precision.
library;

/// Converts a dinar amount (e.g. from user input) to millimes, rounding to
/// the nearest millime to absorb any floating-point noise at the boundary.
int dinarsToMillimes(double dinars) => (dinars * 1000).round();

/// Converts stored millimes back to a dinar `double`, for call sites that
/// still need a plain numeric amount (e.g. chart data, legacy widgets).
double millimesToDinars(int millimes) => millimes / 1000;

/// Formats millimes as a TND string with the correct 3-decimal precision,
/// e.g. `1234` -> `"1.234"`.
String formatMillimes(int millimes) {
  final sign = millimes < 0 ? '-' : '';
  final abs = millimes.abs();
  final whole = abs ~/ 1000;
  final frac = (abs % 1000).toString().padLeft(3, '0');
  return '$sign$whole.$frac';
}
