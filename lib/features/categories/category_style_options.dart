import 'package:flutter/material.dart';

/// Curated icon + color options for categories — the "add category" form
/// picks from these instead of a raw system color/icon picker, so every
/// category ends up visually consistent with the rest of the app.

/// One icon concept per common budget category. Keyed by a short string
/// (stored on [Category.icon]) rather than a raw [IconData] codepoint, so
/// the data stays stable and human-readable across Flutter/font upgrades.
const Map<String, IconData> kCategoryIcons = {
  'groceries': Icons.shopping_basket_rounded,
  'dining': Icons.restaurant_rounded,
  'coffee': Icons.local_cafe_rounded,
  'transport': Icons.directions_car_rounded,
  'fuel': Icons.local_gas_station_rounded,
  'shopping': Icons.shopping_bag_rounded,
  'clothing': Icons.checkroom_rounded,
  'home': Icons.home_rounded,
  'furniture': Icons.chair_rounded,
  'bills': Icons.receipt_long_rounded,
  'utilities': Icons.bolt_rounded,
  'subscriptions': Icons.subscriptions_rounded,
  'phone': Icons.smartphone_rounded,
  'internet': Icons.wifi_rounded,
  'health': Icons.local_hospital_rounded,
  'fitness': Icons.fitness_center_rounded,
  'entertainment': Icons.movie_rounded,
  'travel': Icons.flight_rounded,
  'education': Icons.school_rounded,
  'kids': Icons.child_care_rounded,
  'pets': Icons.pets_rounded,
  'gifts': Icons.card_giftcard_rounded,
  'personalCare': Icons.spa_rounded,
  'insurance': Icons.shield_rounded,
  'taxes': Icons.account_balance_rounded,
  'salary': Icons.payments_rounded,
  'investments': Icons.trending_up_rounded,
  'business': Icons.business_center_rounded,
  'electronics': Icons.devices_rounded,
  'bar': Icons.local_bar_rounded,
  'charity': Icons.volunteer_activism_rounded,
  'repairs': Icons.build_rounded,
  'other': Icons.category_rounded,
};

const String kDefaultCategoryIconKey = 'other';

IconData iconForCategoryKey(String key) => kCategoryIcons[key] ?? kCategoryIcons[kDefaultCategoryIconKey]!;

/// Best-guess icon key from a category name, used to pre-select an icon
/// when the user starts typing a name — they can still override it.
String suggestCategoryIconKey(String name) {
  final n = name.toLowerCase();
  if (n.contains('grocer') || n.contains('market') || n.contains('food')) return 'groceries';
  if (n.contains('dine') || n.contains('restaur') || n.contains('eat') || n.contains('lunch') || n.contains('dinner')) return 'dining';
  if (n.contains('coffee') || n.contains('cafe')) return 'coffee';
  if (n.contains('fuel') || n.contains('gas') || n.contains('petrol')) return 'fuel';
  if (n.contains('transport') || n.contains('uber') || n.contains('taxi') || n.contains('bus') || n.contains('train') || n.contains('car')) return 'transport';
  if (n.contains('cloth') || n.contains('wear') || n.contains('fashion')) return 'clothing';
  if (n.contains('shop') || n.contains('retail') || n.contains('store')) return 'shopping';
  if (n.contains('furnitur') || n.contains('decor')) return 'furniture';
  if (n.contains('rent') || n.contains('hous') || n.contains('mortgage')) return 'home';
  if (n.contains('electric') || n.contains('water') || n.contains('util')) return 'utilities';
  if (n.contains('bill')) return 'bills';
  if (n.contains('sub') || n.contains('stream') || n.contains('netflix') || n.contains('spotify')) return 'subscriptions';
  if (n.contains('phone') || n.contains('mobile')) return 'phone';
  if (n.contains('internet') || n.contains('wifi')) return 'internet';
  if (n.contains('health') || n.contains('doctor') || n.contains('medic') || n.contains('pharma')) return 'health';
  if (n.contains('gym') || n.contains('fitness') || n.contains('sport') || n.contains('workout')) return 'fitness';
  if (n.contains('movie') || n.contains('entertain') || n.contains('game') || n.contains('fun')) return 'entertainment';
  if (n.contains('travel') || n.contains('flight') || n.contains('trip') || n.contains('vacation') || n.contains('hotel')) return 'travel';
  if (n.contains('educat') || n.contains('school') || n.contains('course') || n.contains('tuition') || n.contains('book')) return 'education';
  if (n.contains('kid') || n.contains('child') || n.contains('baby') || n.contains('family')) return 'kids';
  if (n.contains('pet') || n.contains('dog') || n.contains('cat')) return 'pets';
  if (n.contains('gift') || n.contains('present')) return 'gifts';
  if (n.contains('beauty') || n.contains('salon') || n.contains('spa') || n.contains('hair') || n.contains('cosmet')) return 'personalCare';
  if (n.contains('insur')) return 'insurance';
  if (n.contains('tax')) return 'taxes';
  if (n.contains('salary') || n.contains('income') || n.contains('pay') || n.contains('wage')) return 'salary';
  if (n.contains('invest') || n.contains('saving') || n.contains('stock')) return 'investments';
  if (n.contains('business') || n.contains('work') || n.contains('office')) return 'business';
  if (n.contains('electron') || n.contains('tech') || n.contains('gadget') || n.contains('computer')) return 'electronics';
  if (n.contains('bar') || n.contains('alcohol') || n.contains('drink') || n.contains('beer') || n.contains('wine')) return 'bar';
  if (n.contains('charity') || n.contains('donat')) return 'charity';
  if (n.contains('repair') || n.contains('maintenance') || n.contains('fix')) return 'repairs';
  return kDefaultCategoryIconKey;
}

/// A curated category color, with separate light/dark-theme variants — like
/// the app's own semantic tints (theme.tintMintInk vs tintMintInkDk), a
/// single fixed Color reads as too-dark-and-muddy on a dark background, so
/// each swatch needs its own pastel counterpart rather than reusing the
/// light-theme value everywhere.
class CategoryColorOption {
  final String key;
  final Color light;
  final Color dark;
  const CategoryColorOption({required this.key, required this.light, required this.dark});
}

/// The app's 6 semantic tints (matching theme.tintXInk / tintXInkDk exactly)
/// plus 12 more in the same "muted ink in light mode, vivid mid-bright ink in
/// dark mode" family (same hue, boosted saturation, ~60% lightness — vivid
/// against a dark background rather than washed-out pastel), so any category
/// color a user picks blends with the rest of the palette in both themes
/// instead of clashing with it the way a raw Material color wheel (or a
/// single fixed color) would.
const List<CategoryColorOption> kCategoryColorOptions = [
  CategoryColorOption(key: 'mint', light: Color(0xFF2D6948), dark: Color(0xFF6AC894)),
  CategoryColorOption(key: 'coral', light: Color(0xFFB04638), dark: Color(0xFFD66A5C)),
  CategoryColorOption(key: 'butter', light: Color(0xFF8C6315), dark: Color(0xFFF0B442)),
  CategoryColorOption(key: 'lavender', light: Color(0xFF5E4A95), dark: Color(0xFF8772C0)),
  CategoryColorOption(key: 'sky', light: Color(0xFF2F6A95), dark: Color(0xFF5CA3D6)),
  CategoryColorOption(key: 'rose', light: Color(0xFFA24876), dark: Color(0xFFC66C9A)),
  CategoryColorOption(key: 'terracotta', light: Color(0xFFB5652E), dark: Color(0xFFDF8C53)),
  CategoryColorOption(key: 'olive', light: Color(0xFF6B7A33), dark: Color(0xFFB5C969)),
  CategoryColorOption(key: 'teal', light: Color(0xFF2D7A72), dark: Color(0xFF63CFC4)),
  CategoryColorOption(key: 'indigo', light: Color(0xFF4A4E8C), dark: Color(0xFF7579BD)),
  CategoryColorOption(key: 'plum', light: Color(0xFF8C3A6B), dark: Color(0xFFCA68A2)),
  CategoryColorOption(key: 'slate', light: Color(0xFF55606B), dark: Color(0xFF8C99A6)),
  CategoryColorOption(key: 'brick', light: Color(0xFF8C3B2E), dark: Color(0xFFD46E5E)),
  CategoryColorOption(key: 'gold', light: Color(0xFFA67C1E), dark: Color(0xFFEAB848)),
  CategoryColorOption(key: 'forest', light: Color(0xFF3D6B3D), dark: Color(0xFF79B979)),
  CategoryColorOption(key: 'denim', light: Color(0xFF35618C), dark: Color(0xFF649ACE)),
  CategoryColorOption(key: 'wine', light: Color(0xFF7A2E44), dark: Color(0xFFCE6483)),
  CategoryColorOption(key: 'charcoal', light: Color(0xFF3A342D), dark: Color(0xFFA89A8A)),
];

const String kDefaultCategoryColorKey = 'mint';

CategoryColorOption _categoryColorOption(String key) =>
    kCategoryColorOptions.firstWhere((o) => o.key == key, orElse: () => kCategoryColorOptions.first);

/// Resolves a stored color key to the actual [Color] for the current theme
/// brightness — this is the only place that should read [Category.colorKey],
/// so light/dark support stays centralized.
Color colorForCategoryKey(String key, Brightness brightness) {
  final option = _categoryColorOption(key);
  return brightness == Brightness.dark ? option.light : option.dark;
}

/// One-time migration helper: maps a legacy absolute [Color] (from before
/// categories stored a theme-aware color key) to the closest curated key,
/// by nearest distance to that option's light-theme value (the value those
/// old colors were originally picked from).
String nearestCategoryColorKey(Color legacy) {
  double bestDist = double.infinity;
  String bestKey = kDefaultCategoryColorKey;
  for (final option in kCategoryColorOptions) {
    final dr = (legacy.red - option.light.red).toDouble();
    final dg = (legacy.green - option.light.green).toDouble();
    final db = (legacy.blue - option.light.blue).toDouble();
    final dist = dr * dr + dg * dg + db * db;
    if (dist < bestDist) {
      bestDist = dist;
      bestKey = option.key;
    }
  }
  return bestKey;
}
